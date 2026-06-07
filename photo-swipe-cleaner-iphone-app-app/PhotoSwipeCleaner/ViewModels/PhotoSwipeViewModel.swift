import Foundation
import Photos
import SwiftUI
import UIKit

final class PhotoSwipeViewModel: ObservableObject {
    @Published private(set) var authorizationStatus: PHAuthorizationStatus
    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var currentImage: UIImage?
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var keptCount: Int = 0
    @Published private(set) var pendingDeleteCount: Int = 0
    @Published private(set) var estimatedFreeBytes: Int64 = 0
    @Published private(set) var isLoading: Bool = false
    @Published var selectedFilter: PhotoFilter = .all
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var errorMessage: String?

    private let libraryService: PhotoLibraryService
    private let duplicateService: DuplicateDetectionService
    private var pendingDeleteIDs = Set<String>()
    private var keptIDs = Set<String>()
    private var operations: [SwipeOperation] = []
    private var currentRequest: PHImageRequestID?
    private var cacheTargetSize: CGSize = CGSize(width: 900, height: 1200)
    private var cachedAssetIDs = Set<String>()

    init(libraryService: PhotoLibraryService = .shared) {
        self.libraryService = libraryService
        self.duplicateService = DuplicateDetectionService(libraryService: libraryService)
        self.authorizationStatus = libraryService.authorizationStatus
    }

    var totalCount: Int { assets.count }
    var browsedCount: Int { min(currentIndex, assets.count) }
    var currentAsset: PHAsset? { assets.indices.contains(currentIndex) ? assets[currentIndex] : nil }
    var progressText: String { "\(min(currentIndex + 1, assets.count)) / \(assets.count)" }
    var canUndo: Bool { !operations.isEmpty }
    var pendingDeleteAssets: [PHAsset] { assets.filter { pendingDeleteIDs.contains($0.localIdentifier) } }

    var statistics: StatisticsSnapshot {
        StatisticsSnapshot(
            totalCount: totalCount,
            browsedCount: browsedCount,
            keptCount: keptCount,
            pendingDeleteCount: pendingDeleteCount,
            estimatedFreeBytes: estimatedFreeBytes
        )
    }

    func refreshAuthorization() {
        authorizationStatus = libraryService.authorizationStatus
    }

    func requestAuthorization() {
        libraryService.requestAuthorization { [weak self] status in
            self?.authorizationStatus = status
            if status == .authorized || status == .limited {
                self?.reloadAssets()
            }
        }
    }

    func reloadAssets() {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else { return }
        isLoading = true
        currentImage = nil
        libraryService.cancelRequest(currentRequest)

        DispatchQueue.global(qos: .userInitiated).async { [selectedFilter, libraryService] in
            let fetched = libraryService.fetchAssets(filter: selectedFilter)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.assets = fetched
                self.currentIndex = 0
                self.pendingDeleteIDs.removeAll()
                self.keptIDs.removeAll()
                self.operations.removeAll()
                self.pendingDeleteCount = 0
                self.keptCount = 0
                self.estimatedFreeBytes = 0
                self.duplicateGroups = []
                self.isLoading = false
                self.loadCurrentImage()
                self.updateCacheWindow()
            }
        }
    }

    func updateTargetSize(_ size: CGSize, scale: CGFloat) {
        let width = max(size.width * scale, 320)
        let height = max(size.height * scale, 480)
        cacheTargetSize = CGSize(width: width, height: height)
        loadCurrentImage()
        updateCacheWindow()
    }

    func loadCurrentImage() {
        libraryService.cancelRequest(currentRequest)
        currentImage = nil
        guard let asset = currentAsset else { return }
        currentRequest = libraryService.requestDisplayImage(for: asset, targetSize: cacheTargetSize) { [weak self] image in
            self?.currentImage = image
        }
    }

    func decide(_ decision: SwipeDecision) {
        guard let asset = currentAsset else { return }

        operations.append(SwipeOperation(asset: asset, index: currentIndex, decision: decision))
        if operations.count > 100 {
            operations.removeFirst()
        }

        switch decision {
        case .keep:
            keptIDs.insert(asset.localIdentifier)
            pendingDeleteIDs.remove(asset.localIdentifier)
        case .delete:
            pendingDeleteIDs.insert(asset.localIdentifier)
            keptIDs.remove(asset.localIdentifier)
            estimatedFreeBytes += libraryService.approximateFileSize(for: asset)
        }

        recalculateCounts()
        advance()
    }

    func undoLastOperation() {
        guard let operation = operations.popLast() else { return }
        currentIndex = operation.index

        switch operation.decision {
        case .keep:
            keptIDs.remove(operation.asset.localIdentifier)
        case .delete:
            pendingDeleteIDs.remove(operation.asset.localIdentifier)
            estimatedFreeBytes = max(0, estimatedFreeBytes - libraryService.approximateFileSize(for: operation.asset))
        }

        recalculateCounts()
        loadCurrentImage()
        updateCacheWindow()
    }

    func deletePendingAssets(completion: @escaping (Bool) -> Void) {
        let assetsToDelete = pendingDeleteAssets
        guard !assetsToDelete.isEmpty else {
            completion(true)
            return
        }

        libraryService.deleteAssets(assetsToDelete) { [weak self] success, error in
            if success {
                self?.pendingDeleteIDs.removeAll()
                self?.estimatedFreeBytes = 0
                self?.reloadAssets()
            } else {
                self?.errorMessage = error?.localizedDescription ?? "删除失败"
            }
            completion(success)
        }
    }

    func markAssetsForDeletion(_ assets: [PHAsset]) {
        for asset in assets {
            if !pendingDeleteIDs.contains(asset.localIdentifier) {
                pendingDeleteIDs.insert(asset.localIdentifier)
                estimatedFreeBytes += libraryService.approximateFileSize(for: asset)
            }
        }
        recalculateCounts()
    }

    func generateDuplicateGroups() {
        isLoading = true
        let sourceAssets = assets
        DispatchQueue.global(qos: .userInitiated).async { [duplicateService] in
            let groups = duplicateService.findDuplicateGroups(in: sourceAssets)
            DispatchQueue.main.async { [weak self] in
                self?.duplicateGroups = groups
                self?.isLoading = false
            }
        }
    }

    func metadata(for asset: PHAsset, settings: AppSettings) -> String {
        libraryService.formattedMetadata(for: asset, showDate: settings.showCaptureDate, showSize: settings.showPhotoSize)
    }

    private func advance() {
        currentIndex = min(currentIndex + 1, assets.count)
        loadCurrentImage()
        updateCacheWindow()
    }

    private func recalculateCounts() {
        pendingDeleteCount = pendingDeleteIDs.count
        keptCount = keptIDs.count
    }

    private func updateCacheWindow() {
        let upcoming = (currentIndex + 1...currentIndex + 2).compactMap { index in
            assets.indices.contains(index) ? assets[index] : nil
        }
        let upcomingIDs = Set(upcoming.map(\.localIdentifier))
        let oldAssets = assets.filter { cachedAssetIDs.contains($0.localIdentifier) && !upcomingIDs.contains($0.localIdentifier) }

        libraryService.stopCachingAssets(oldAssets, targetSize: cacheTargetSize)
        libraryService.cacheAssets(upcoming, targetSize: cacheTargetSize)
        cachedAssetIDs = upcomingIDs
    }
}

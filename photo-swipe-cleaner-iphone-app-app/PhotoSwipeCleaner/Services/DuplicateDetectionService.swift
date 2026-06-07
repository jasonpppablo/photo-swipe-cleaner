import Foundation
import Photos

final class DuplicateDetectionService {
    private let libraryService: PhotoLibraryService

    init(libraryService: PhotoLibraryService = .shared) {
        self.libraryService = libraryService
    }

    func findDuplicateGroups(in assets: [PHAsset], limit: Int = 5000) -> [DuplicateGroup] {
        let candidates = Array(assets.prefix(limit)).filter { $0.mediaType == .image }
        let sizeBuckets = Dictionary(grouping: candidates) { asset in
            libraryService.approximateFileSize(for: asset)
        }

        var groups: [DuplicateGroup] = []

        for (size, sameSizeAssets) in sizeBuckets where size > 0 && sameSizeAssets.count > 1 {
            let dimensionBuckets = Dictionary(grouping: sameSizeAssets) { asset in
                "\(asset.pixelWidth)x\(asset.pixelHeight)"
            }

            for (_, sameDimensionAssets) in dimensionBuckets where sameDimensionAssets.count > 1 {
                let sorted = sameDimensionAssets.sorted {
                    ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast)
                }

                var current: [PHAsset] = []
                for asset in sorted {
                    if let previous = current.last,
                       areCloseInTime(previous, asset) {
                        current.append(asset)
                    } else {
                        appendGroupIfNeeded(current, size: size, groups: &groups)
                        current = [asset]
                    }
                }
                appendGroupIfNeeded(current, size: size, groups: &groups)
            }
        }

        return groups.sorted { $0.estimatedBytes > $1.estimatedBytes }
    }

    private func areCloseInTime(_ left: PHAsset, _ right: PHAsset) -> Bool {
        guard let leftDate = left.creationDate, let rightDate = right.creationDate else { return true }
        return abs(leftDate.timeIntervalSince(rightDate)) <= 10
    }

    private func appendGroupIfNeeded(_ assets: [PHAsset], size: Int64, groups: inout [DuplicateGroup]) {
        guard assets.count > 1 else { return }
        let id = assets.map(\.localIdentifier).joined(separator: "|")
        let removableBytes = max(Int64(assets.count - 1), 0) * size
        groups.append(DuplicateGroup(id: id, assets: assets, estimatedBytes: removableBytes))
    }
}

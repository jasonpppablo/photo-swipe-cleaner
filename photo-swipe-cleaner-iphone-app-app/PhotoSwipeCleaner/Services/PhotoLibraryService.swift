import Foundation
import Photos
import UIKit

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager()
    private let imageQueue = DispatchQueue(label: "PhotoSwipeCleaner.image.queue", qos: .userInitiated)

    private init() {
        imageManager.allowsCachingHighQualityImages = false
    }

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    func fetchAssets(filter: PhotoFilter) -> [PHAsset] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        switch filter {
        case .videos:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case .screenshots:
            options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        case .livePhotos:
            options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        case .favorites:
            options.predicate = NSPredicate(format: "favorite == YES")
        case .olderThan3Years:
            options.predicate = oldAssetPredicate(years: 3)
        case .olderThan5Years:
            options.predicate = oldAssetPredicate(years: 5)
        case .olderThan10Years:
            options.predicate = oldAssetPredicate(years: 10)
        case .all, .largest:
            break
        }

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        if filter == .largest {
            return assets.sorted { approximateFileSize(for: $0) > approximateFileSize(for: $1) }
        }
        return assets
    }

    func requestDisplayImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if image != nil || !degraded {
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }

    func requestFullScreenImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func cancelRequest(_ id: PHImageRequestID?) {
        guard let id = id else { return }
        imageManager.cancelImageRequest(id)
    }

    func cacheAssets(_ assets: [PHAsset], targetSize: CGSize) {
        guard !assets.isEmpty else { return }
        imageQueue.async { [imageManager] in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFit, options: options)
        }
    }

    func stopCachingAssets(_ assets: [PHAsset], targetSize: CGSize) {
        guard !assets.isEmpty else { return }
        imageQueue.async { [imageManager] in
            imageManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFit, options: nil)
        }
    }

    func deleteAssets(_ assets: [PHAsset], completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    func approximateFileSize(for asset: PHAsset) -> Int64 {
        PHAssetResource.assetResources(for: asset).reduce(Int64(0)) { total, resource in
            if let number = resource.value(forKey: "fileSize") as? NSNumber {
                return total + number.int64Value
            }
            return total
        }
    }

    func formattedMetadata(for asset: PHAsset, showDate: Bool, showSize: Bool) -> String {
        var values: [String] = []
        if showDate, let date = asset.creationDate {
            values.append(DateFormatter.photoShort.string(from: date))
        }
        if showSize {
            values.append(ByteCountFormatter.storage.string(fromByteCount: approximateFileSize(for: asset)))
        }
        return values.joined(separator: " · ")
    }

    private func oldAssetPredicate(years: Int) -> NSPredicate {
        let date = Calendar.current.date(byAdding: .year, value: -years, to: Date()) ?? Date()
        return NSPredicate(format: "creationDate < %@", date as NSDate)
    }
}

import Photos

struct DuplicateGroup: Identifiable {
    let id: String
    let assets: [PHAsset]
    let estimatedBytes: Int64

    var removableAssets: [PHAsset] {
        Array(assets.dropFirst())
    }
}

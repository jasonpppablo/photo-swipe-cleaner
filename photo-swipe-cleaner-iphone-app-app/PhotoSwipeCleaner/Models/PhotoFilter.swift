import Foundation

enum PhotoFilter: String, CaseIterable, Identifiable {
    case all
    case screenshots
    case videos
    case livePhotos
    case favorites
    case largest
    case olderThan3Years
    case olderThan5Years
    case olderThan10Years

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .screenshots: return "截图"
        case .videos: return "视频"
        case .livePhotos: return "Live Photo"
        case .favorites: return "收藏"
        case .largest: return "大文件"
        case .olderThan3Years: return "3年以上"
        case .olderThan5Years: return "5年以上"
        case .olderThan10Years: return "10年以上"
        }
    }
}

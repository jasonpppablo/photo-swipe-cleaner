import Foundation

enum SwipeDecision: String {
    case keep
    case delete

    var title: String {
        switch self {
        case .keep: return "保留"
        case .delete: return "删除"
        }
    }
}

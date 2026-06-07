import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var viewModel: PhotoSwipeViewModel

    var body: some View {
        NavigationView {
            List {
                statRow(title: "总照片数", value: "\(viewModel.statistics.totalCount)")
                statRow(title: "已浏览", value: "\(viewModel.statistics.browsedCount)")
                statRow(title: "保留", value: "\(viewModel.statistics.keptCount)")
                statRow(title: "待删除", value: "\(viewModel.statistics.pendingDeleteCount)")
                statRow(title: "预计释放", value: ByteCountFormatter.storage.string(fromByteCount: viewModel.statistics.estimatedFreeBytes))
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("统计")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

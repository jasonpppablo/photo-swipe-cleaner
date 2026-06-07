import SwiftUI

struct DuplicateGroupsView: View {
    @EnvironmentObject private var viewModel: PhotoSwipeViewModel
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: viewModel.generateDuplicateGroups) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text(viewModel.isLoading ? "检测中" : "开始检测疑似重复照片")
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                ForEach(viewModel.duplicateGroups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(group.assets.count) 张疑似重复")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Text(ByteCountFormatter.storage.string(fromByteCount: group.estimatedBytes))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Button("保留第一张，删除其余\(group.removableAssets.count)张") {
                            viewModel.markAssetsForDeletion(group.removableAssets)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("重复照片")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

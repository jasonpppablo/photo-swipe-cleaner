import Photos
import SwiftUI
import UIKit

struct FilterView: View {
    @EnvironmentObject private var viewModel: PhotoSwipeViewModel

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(PhotoFilter.allCases) { filter in
                        Button(action: {
                            viewModel.selectedFilter = filter
                            viewModel.reloadAssets()
                        }) {
                            HStack {
                                Text(filter.title)
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }

                if viewModel.authorizationStatus == .limited {
                    Section {
                        Button("管理限制访问照片") {
                            presentLimitedLibraryPicker()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("筛选")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func presentLimitedLibraryPicker() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let controller = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }
}

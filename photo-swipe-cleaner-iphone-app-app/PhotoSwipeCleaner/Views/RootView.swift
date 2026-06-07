import Photos
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: PhotoSwipeViewModel

    var body: some View {
        Group {
            if viewModel.authorizationStatus == .authorized || viewModel.authorizationStatus == .limited {
                MainTabView()
                    .onAppear {
                        if viewModel.assets.isEmpty {
                            viewModel.reloadAssets()
                        }
                    }
            } else {
                AuthorizationView()
            }
        }
        .onAppear {
            viewModel.refreshAuthorization()
        }
    }
}

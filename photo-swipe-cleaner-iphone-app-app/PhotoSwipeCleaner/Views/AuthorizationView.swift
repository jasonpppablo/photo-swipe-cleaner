import Photos
import SwiftUI
import UIKit

struct AuthorizationView: View {
    @EnvironmentObject private var viewModel: PhotoSwipeViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.accentColor)

            VStack(spacing: 10) {
                Text("照片左滑清理")
                    .font(.system(size: 30, weight: .bold))
                Text(statusMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Button(action: primaryAction) {
                Text(primaryButtonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }

    private var statusMessage: String {
        switch viewModel.authorizationStatus {
        case .denied, .restricted:
            return "照片权限已关闭，请在系统设置中允许访问后继续。"
        default:
            return "允许访问照片后即可快速左滑删除、右滑保留。支持限制访问模式。"
        }
    }

    private var primaryButtonTitle: String {
        switch viewModel.authorizationStatus {
        case .denied, .restricted:
            return "打开系统设置"
        default:
            return "允许访问照片"
        }
    }

    private func primaryAction() {
        switch viewModel.authorizationStatus {
        case .denied, .restricted:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        default:
            viewModel.requestAuthorization()
        }
    }
}

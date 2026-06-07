import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("深色模式", isOn: $settings.isDarkMode)
                    Toggle("震动反馈", isOn: $settings.hapticsEnabled)
                    Toggle("删除前确认", isOn: $settings.confirmBeforeDelete)
                }

                Section {
                    Toggle("显示拍摄时间", isOn: $settings.showCaptureDate)
                    Toggle("显示照片大小", isOn: $settings.showPhotoSize)
                }
            }
            .navigationTitle("设置")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

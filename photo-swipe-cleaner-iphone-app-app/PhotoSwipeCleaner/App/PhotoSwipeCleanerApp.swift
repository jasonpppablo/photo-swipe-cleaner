import SwiftUI

@main
struct PhotoSwipeCleanerApp: App {
    @StateObject private var swipeViewModel = PhotoSwipeViewModel()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(swipeViewModel)
                .environmentObject(settings)
                .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        }
    }
}

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SwipeView()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("清理")
                }

            FilterView()
                .tabItem {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("筛选")
                }

            DuplicateGroupsView()
                .tabItem {
                    Image(systemName: "square.on.square")
                    Text("重复")
                }

            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("统计")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
        }
    }
}

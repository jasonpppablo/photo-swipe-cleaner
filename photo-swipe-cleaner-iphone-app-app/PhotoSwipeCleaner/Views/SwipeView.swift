import Photos
import SwiftUI
import UIKit

struct SwipeView: View {
    @EnvironmentObject private var viewModel: PhotoSwipeViewModel
    @EnvironmentObject private var settings: AppSettings
    @State private var dragOffset: CGSize = .zero
    @State private var showDeleteAlert = false
    @State private var showFullScreen = false
    @State private var overlayDecision: SwipeDecision?

    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                VStack(spacing: 16) {
                    header

                    ZStack {
                        SwipeCardView(
                            image: viewModel.currentImage,
                            asset: viewModel.currentAsset,
                            metadata: currentMetadata,
                            onTap: { if viewModel.currentAsset != nil { showFullScreen = true } }
                        )
                        .frame(width: proxy.size.width - 32, height: max(proxy.size.height - 210, 320))
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
                        .gesture(cardDrag)
                        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: dragOffset)

                        decisionOverlay
                    }
                    .onAppear {
                        viewModel.updateTargetSize(CGSize(width: proxy.size.width - 32, height: max(proxy.size.height - 210, 320)), scale: UIScreen.main.scale)
                    }

                    controls
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showFullScreen) {
            if let asset = viewModel.currentAsset {
                FullScreenPhotoView(asset: asset)
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("确定删除\(viewModel.pendingDeleteCount)张照片？"),
                message: Text("删除后照片会进入系统相册的最近删除。"),
                primaryButton: .destructive(Text("确认删除")) {
                    viewModel.deletePendingAssets { _ in }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.assets.isEmpty ? "0 / 0" : viewModel.progressText)
                    .font(.system(size: 28, weight: .bold))
                Text(viewModel.selectedFilter.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                if settings.confirmBeforeDelete {
                    showDeleteAlert = true
                } else {
                    viewModel.deletePendingAssets { _ in }
                }
            }) {
                VStack(spacing: 2) {
                    Text("待删除")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(viewModel.pendingDeleteCount)")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.red)
                .frame(width: 86, height: 54)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .disabled(viewModel.pendingDeleteCount == 0)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            GlassButton(title: "保留", systemName: "heart.fill", tint: .green) {
                performButtonDecision(.keep)
            }
            GlassButton(title: "删除", systemName: "trash.fill", tint: .red) {
                performButtonDecision(.delete)
            }
            GlassButton(title: "撤销", systemName: "arrow.uturn.backward", tint: .blue) {
                viewModel.undoLastOperation()
                Haptics.impact(enabled: settings.hapticsEnabled, style: .light)
            }
            .opacity(viewModel.canUndo ? 1 : 0.45)
            .disabled(!viewModel.canUndo)
        }
        .frame(height: 56)
    }

    private var cardDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                if value.translation.width > 70 {
                    overlayDecision = .keep
                } else if value.translation.width < -70 {
                    overlayDecision = .delete
                } else {
                    overlayDecision = nil
                }
            }
            .onEnded { value in
                if value.translation.width > 120 {
                    finishSwipe(.keep, exitX: 700)
                } else if value.translation.width < -120 {
                    finishSwipe(.delete, exitX: -700)
                } else {
                    overlayDecision = nil
                    dragOffset = .zero
                }
            }
    }

    private var decisionOverlay: some View {
        Group {
            if let decision = overlayDecision {
                Text(decision.title)
                    .font(.system(size: 38, weight: .black))
                    .foregroundColor(decision == .keep ? .green : .red)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(decision == .keep ? Color.green : Color.red, lineWidth: 4)
                    )
                    .rotationEffect(.degrees(decision == .keep ? -12 : 12))
                    .offset(x: decision == .keep ? -70 : 70, y: -130)
            }
        }
    }

    private var currentMetadata: String {
        guard let asset = viewModel.currentAsset else { return "" }
        return viewModel.metadata(for: asset, settings: settings)
    }

    private func performButtonDecision(_ decision: SwipeDecision) {
        finishSwipe(decision, exitX: decision == .keep ? 700 : -700)
    }

    private func finishSwipe(_ decision: SwipeDecision, exitX: CGFloat) {
        guard viewModel.currentAsset != nil else { return }
        overlayDecision = decision
        Haptics.notification(enabled: settings.hapticsEnabled, type: decision == .keep ? .success : .warning)
        withAnimation(.easeIn(duration: 0.20)) {
            dragOffset = CGSize(width: exitX, height: 40)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            viewModel.decide(decision)
            dragOffset = .zero
            overlayDecision = nil
        }
    }
}

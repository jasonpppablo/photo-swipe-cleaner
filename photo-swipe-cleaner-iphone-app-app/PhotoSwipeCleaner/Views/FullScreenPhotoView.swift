import Photos
import SwiftUI
import UIKit

struct FullScreenPhotoView: View {
    let asset: PHAsset
    @Environment(\.presentationMode) private var presentationMode
    @State private var image: UIImage?
    @State private var dragOffset: CGFloat = 0
    private let libraryService = PhotoLibraryService.shared

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                Color.black.edgesIgnoringSafeArea(.all)

                if let image = image {
                    ZoomableImageView(image: image)
                        .offset(y: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.height > 0 {
                                        dragOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 110 {
                                        presentationMode.wrappedValue.dismiss()
                                    } else {
                                        withAnimation(.spring()) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .padding(20)
            }
            .onAppear {
                let size = CGSize(width: proxy.size.width * UIScreen.main.scale, height: proxy.size.height * UIScreen.main.scale)
                _ = libraryService.requestFullScreenImage(for: asset, targetSize: size) { loaded in
                    image = loaded
                }
            }
        }
    }
}

import Photos
import SwiftUI
import UIKit

struct SwipeCardView: View {
    let image: UIImage?
    let asset: PHAsset?
    let metadata: String
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 14) {
                    ProgressView()
                    Text(asset == nil ? "已完成" : "加载中")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !metadata.isEmpty {
                Text(metadata)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(VisualEffectBlur(style: .systemUltraThinMaterialDark))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(14)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture(perform: onTap)
        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

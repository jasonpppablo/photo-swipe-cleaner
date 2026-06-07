import SwiftUI

struct GlassButton: View {
    let title: String
    let systemName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    VisualEffectBlur(style: .systemThinMaterial)
                    Color.white.opacity(0.10)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

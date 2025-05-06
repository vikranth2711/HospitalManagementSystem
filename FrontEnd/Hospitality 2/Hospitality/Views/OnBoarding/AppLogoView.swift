import SwiftUI

struct AppLogoView: View {
    var body: some View {
        ZStack {
            // Outer gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "4A90E2"), Color(hex: "2B6CB0")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            // Inner white circle for contrast
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
            
            // Cross + heartbeat
            ZStack {
                // Cross arms
                Group {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "4A90E2"))
                        .frame(width: 10, height: 20)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "4A90E2"))
                        .frame(width: 20, height: 10)
                }
                
                // Heartbeat line
                Path { path in
                    // adjust these points to center within the cross
                    let startX: CGFloat = -22
                    let midY: CGFloat = 0
                    path.move(to: CGPoint(x: startX, y: midY))
                    path.addLine(to: CGPoint(x: startX + 6, y: midY))
                    path.addLine(to: CGPoint(x: startX + 10, y: midY + 8))
                    path.addLine(to: CGPoint(x: startX + 18, y: midY - 10))
                    path.addLine(to: CGPoint(x: startX + 26, y: midY + 8))
                    path.addLine(to: CGPoint(x: startX + 30, y: midY))
                }
                .stroke(Color.red, lineWidth: 2)
            }
            .frame(width: 28, height: 28)
        }
    }
}

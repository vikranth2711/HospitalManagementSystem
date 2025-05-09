import SwiftUI


struct SplashScreen: View {
    @State private var opacity = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var iconOpacity: CGFloat = 0.0
    @State private var crossScale: CGFloat = 0.5
    @State private var heartbeatOpacity: CGFloat = 0.0
    @State private var glowOpacity: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E6F0FA"),
                    colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F9FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle background patterns (reduced to 4 for performance)
            ForEach(0..<4) { _ in
                Circle()
                    .fill(colorScheme == .dark ? Color.blue.opacity(0.04) : Color.blue.opacity(0.02))
                    .frame(width: CGFloat.random(in: 60...120))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 4)
            }
            
            // Icon and text
            VStack(spacing: 8) {
                // New Medicare Icon
                ZStack {
                    // Base gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "4A90E2"), Color(hex: "2B6CB0")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.blue.opacity(glowOpacity * 0.5), radius: 12, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .stroke(Color.blue.opacity(glowOpacity), lineWidth: 4)
                                .blur(radius: 4)
                        )
                        .opacity(iconOpacity)
                    
                    // Inner white circle for contrast
                    Circle()
                        .fill(Color.white)
                        .frame(width: 90, height: 90)
                        .opacity(iconOpacity)
                    
                    // Medical cross with heartbeat
                    ZStack {
                        // Cross
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "4A90E2"))
                            .frame(width: 30, height: 60)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "4A90E2"))
                            .frame(width: 60, height: 30)
                        
                        // Heartbeat line
                        Path { path in
                            path.move(to: CGPoint(x: -25, y: 0))
                            path.addLine(to: CGPoint(x: -15, y: 0))
                            path.addLine(to: CGPoint(x: -10, y: 10))
                            path.addLine(to: CGPoint(x: 0, y: -15))
                            path.addLine(to: CGPoint(x: 10, y: 10))
                            path.addLine(to: CGPoint(x: 15, y: 0))
                            path.addLine(to: CGPoint(x: 25, y: 0))
                        }
                        .stroke(Color.red, lineWidth: 3)
                        .offset(y: -10)
                        .opacity(heartbeatOpacity)
                    }
                    .frame(width: 80, height: 80)
                    .scaleEffect(crossScale)
                    .opacity(iconOpacity)
                }
                .scaleEffect(scale)
                
                // Brand text
                Text("Medicare")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2B6CB0"))
                    .padding(.top, 12)
                
                Text("Streamlined Hospital Management")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
            }
            .opacity(opacity)
            .onAppear {
                // Icon fade-in and pulse animation
                withAnimation(.easeInOut(duration: 0.8)) {
                    iconOpacity = 1.0
                    crossScale = 1.0
                }
                
                // Heartbeat fade-in with slight delay
                withAnimation(.easeInOut(duration: 0.6).delay(0.4)) {
                    heartbeatOpacity = 1.0
                }
                
                // Pulse effect for cross
                withAnimation(.easeInOut(duration: 1.2).repeatCount(2, autoreverses: true)) {
                    crossScale = 1.1
                }
                
                // Glow effect fades out
                withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                    glowOpacity = 0.0
                }
                
                // Overall scale and opacity animation
                withAnimation(.easeInOut(duration: 1.8)) {
                    scale = 1.15
                    opacity = 0.9
                }
                
                // Trigger completion after 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        opacity = 0
                        scale = 0.7
                        iconOpacity = 0
                        heartbeatOpacity = 0
                    }
                    onComplete()
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashScreen(onComplete: {})
                .preferredColorScheme(.light)
            SplashScreen(onComplete: {})
                .preferredColorScheme(.dark)
        }
    }
}

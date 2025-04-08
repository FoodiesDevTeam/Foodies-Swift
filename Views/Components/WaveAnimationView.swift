import SwiftUI

struct WaveAnimationView: View {
    @State private var offsetX1: CGFloat = 0
    @State private var offsetX2: CGFloat = 150
    @State private var offsetX3: CGFloat = 300
    @State private var amplitude1: CGFloat = 40
    @State private var amplitude2: CGFloat = 25
    @State private var amplitude3: CGFloat = 15
    
    private let colors: [Color] = [
        Color(hex: "#4A90E2"),  // Mavi
        Color(hex: "#8E44AD"),  // Mor
        Color(hex: "#FF5E99")   // Pembe
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let availableHeight = geometry.size.height - 80
            
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                ZStack(alignment: .trailing) {
                    WaveLine(waveHeight: amplitude1, xOffset: offsetX1, width: screenWidth * 2)
                        .fill(colors[0].opacity(0.6))
                        .frame(width: screenWidth * 2, height: availableHeight)
                        .offset(x: screenWidth)
                        
                    WaveLine(waveHeight: amplitude2, xOffset: offsetX2, width: screenWidth * 2)
                        .fill(colors[1].opacity(0.5))
                        .frame(width: screenWidth * 2, height: availableHeight)
                        .offset(x: screenWidth)
                        
                    WaveLine(waveHeight: amplitude3, xOffset: offsetX3, width: screenWidth * 2)
                        .fill(colors[2].opacity(0.4))
                        .frame(width: screenWidth * 2, height: availableHeight)
                        .offset(x: screenWidth)
                }
                .frame(height: availableHeight)
                .offset(y: 120)
                .clipped()
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    amplitude1 = 20
                    amplitude2 = 15
                    amplitude3 = 10
                }
                
                withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                    offsetX1 = -screenWidth
                }
                
                withAnimation(Animation.linear(duration: 6).repeatForever(autoreverses: false)) {
                    offsetX2 = -screenWidth
                }
                
                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                    offsetX3 = -screenWidth
                }
            }
        }
    }
}

struct WaveLine: Shape {
    var waveHeight: CGFloat
    var xOffset: CGFloat
    var width: CGFloat
    
    var animatableData: CGFloat {
        get { xOffset }
        set { xOffset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midHeight = rect.height * 0.5
        
        path.move(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: midHeight))
        
        for x in stride(from: rect.width, through: 0, by: -1) {
            let angle = 2 * .pi * (x + xOffset) / width
            let y = midHeight - waveHeight * sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct WaveAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        WaveAnimationView()
            .frame(height: 400)
    }
}


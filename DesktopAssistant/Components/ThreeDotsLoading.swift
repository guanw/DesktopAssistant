import SwiftUI

struct ThreeDotsLoading: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .scaleEffect(animate ? 0.8 : 1)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(0.2 * Double(index)), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

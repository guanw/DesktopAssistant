import SwiftUI

struct PlaygroundView: View {
    var body: some View {
        VStack {
            Text("Playground view")
                .font(.largeTitle)
                .padding()
        }.frame(width: Constants.CHAT_WIDTH, height: 400)

    }
}

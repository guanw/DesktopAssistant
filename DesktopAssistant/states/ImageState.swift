import Combine
import SwiftUI

class ImageState: ObservableObject {
    static let shared = ImageState()
    @Published var selectedFileUrl: URL? = nil
}

import Combine
import SwiftUI

class ImageState: ObservableObject {
    @Published var selectedFileUrl: URL? = nil
}

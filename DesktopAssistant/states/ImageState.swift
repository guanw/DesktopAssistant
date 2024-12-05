import Combine
import SwiftUI

class ImageState: ObservableObject {
    @Published var selectedFileUrl: URL? = nil
    @Published var isAttachPageClickableHovered: Bool = false
}

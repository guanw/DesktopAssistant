

import Foundation

class ImageUtil {
    static func encodeImageToBase64(imagePath: String) -> String? {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else {
            Logger.shared.log("Failed to load image data")
            return nil
        }
        return "data:image/jpeg;base64,"+imageData.base64EncodedString()
    }
}


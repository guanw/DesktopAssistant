import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct ScreenshotButton: View {
    @ObservedObject var imageState : ImageState
    @State private var isScreenshotClickableHovered = false
    var body: some View {
        Button(action: {
            TakeScreensShots(fileNamePrefix: "screenshot")
        }) {
            HStack {
                Image(systemName: "scroll")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .help("Take screenshot and attach")
                    .foregroundColor(isScreenshotClickableHovered ? .blue : .primary) // Change color on hover
                    .onHover { hovering in
                        isScreenshotClickableHovered = hovering
                    }
            }
        }.buttonStyle(BorderlessButtonStyle())
    }

    private func TakeScreensShots(fileNamePrefix: String){
       var displayCount: UInt32 = 0;
       var result = CGGetActiveDisplayList(0, nil, &displayCount)
       if (result != CGError.success) {
           Logger.shared.log("error: \(result)")
           return
       }
       let allocated = Int(displayCount)
       let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
       result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)

       if (result != CGError.success) {
           Logger.shared.log("error: \(result)")
           return
       }

       guard let desktopDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
           Logger.shared.log("Unable to locate Desktop directory.")
           return
       }

       for i in 1...displayCount {
           let unixTimestamp = CreateTimeStamp()
           let fileUrl = URL(fileURLWithPath: fileNamePrefix + "_" + "\(unixTimestamp)" + "_" + "\(i)" + ".jpg", isDirectory: true)
           let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
           let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
           let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!


           do {
               try jpegData.write(to: fileUrl, options: .atomic)
           }
           catch {Logger.shared.log("error: \(error)")}

           imageState.selectedFileUrl = fileUrl
       }
   }

    private func CreateTimeStamp() -> Int32
    {
        return Int32(Date().timeIntervalSince1970)
    }
}




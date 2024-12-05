import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct ImageAttachment: View {
    @ObservedObject var imageState : ImageState
    var body: some View {
        Button(action: {
            openImagePicker()
        }) {
            HStack {
                Image(systemName: "paperclip.circle")
                    .resizable()
                    .frame(width: 24, height: 24)

                Text(
                    imageState.selectedFileUrl?.lastPathComponent != nil
                        ? "Attach Image: \(imageState.selectedFileUrl!.lastPathComponent)"
                        : "Attach Image"

                )
            }
            .foregroundColor(imageState.isAttachPageClickableHovered ? .blue : .primary) // Change color on hover
            .onHover { hovering in
                imageState.isAttachPageClickableHovered = hovering
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    private func openImagePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.jpeg] // Allow image file types
        openPanel.allowsMultipleSelection = false // Single file selection
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Select an Image (jpeg)"

        if openPanel.runModal() == .OK, let selectedFileURL = openPanel.url {
            if let _ = NSImage(contentsOf: selectedFileURL) {
                imageState.selectedFileUrl = selectedFileURL
            } else {
                Logger.shared.log("Failed to load image")
            }
        }
    }
}



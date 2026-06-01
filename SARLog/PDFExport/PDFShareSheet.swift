import SwiftUI
import UIKit

struct PDFShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct PDFShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

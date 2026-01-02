//
//  ContentView.swift
//
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Photos
import UIKit

// MARK: - Photos Permission Helpers
enum PhotosAddStatus {
    case authorized, limited, denied, notDetermined, restricted

    static func from(_ s: PHAuthorizationStatus) -> PhotosAddStatus {
        switch s {
        case .authorized:    return .authorized
        case .limited:       return .limited
        case .denied:        return .denied
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        @unknown default:    return .denied
        }
    }
}

func currentAddStatus() -> PhotosAddStatus {
    PhotosAddStatus.from(PHPhotoLibrary.authorizationStatus(for: .addOnly))
}

func requestAddOnlyAccess() async -> PhotosAddStatus {
    await withCheckedContinuation { cont in
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { s in
            cont.resume(returning: PhotosAddStatus.from(s))
        }
    }
}

func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}

// MARK: - THEME
private enum Theme {
    static let corner: CGFloat = 18
    static let cardShadow: CGFloat = 12
    static let spacing: CGFloat = 16
    static let checkerSize: CGFloat = 14
}



// MARK: - Utilities
typealias XImage = UIImage

// Checkerboard to visualize PNG transparency
struct Checkerboard: View {
    var size: CGFloat = Theme.checkerSize
    var body: some View {
        GeometryReader { _ in
            Canvas { ctx, rect in
                let s = size
                let cols = Int(ceil(rect.width / s))
                let rows = Int(ceil(rect.height / s))
                for r in 0..<rows {
                    for c in 0..<cols {
                        let color: Color = ((r + c) % 2 == 0) ? Color(.systemGray5) : Color(.systemGray4)
                        let tile = CGRect(x: CGFloat(c)*s, y: CGFloat(r)*s, width: s, height: s)
                        ctx.fill(Path(tile), with: .color(color))
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }
}

// Card shell
struct Card<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title { Text(title).font(.title3.weight(.semibold)) }
            content()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: Theme.cardShadow, y: 6)
    }
}

// Big primary button
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// Share sheet wrapper
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Main View
struct ContentView: View {
    // State
    @State private var sourceImage: XImage?
    @State private var resultImage: XImage?
    @State private var sourceFilename: String = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    // Pickers
    @State private var showFileImporter = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // Saves/alerts
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @State private var photosStatus: PhotosAddStatus = currentAddStatus()
    @State private var showShare = false
    @State private var shareItem: UIImage?

    // API

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    // Large inline header
                    Text("BEN2 Background Removal")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.horizontal, 4)

                    // SOURCE
                    Card(title: "Source") {
                        if let img = sourceImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            if !sourceFilename.isEmpty {
                                Text(sourceFilename)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundColor(.secondary.opacity(0.6))
                                .frame(height: 180)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "photo.on.rectangle.angled").font(.system(size: 28))
                                        Text("Pick an image from Files or Photos")
                                            .font(.callout).foregroundColor(.secondary)
                                    }
                                )
                        }

                        HStack(spacing: 12) {
                            Button {
                                showFileImporter = true
                            } label: {
                                Label("Files", systemImage: "folder")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                Label("Photos", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // ACTION
                    Button {
                        Task { await runRemoval() }
                    } label: {
                        HStack {
                            Image(systemName: "scissors")
                            Text(isBusy ? "Processing…" : "Remove Background")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(sourceImage == nil || isBusy)
                    .overlay {
                        if isBusy {
                            ProgressView().tint(.white)
                                .allowsHitTesting(false)
                        }
                    }

                    // RESULT
                    Card(title: "Result (PNG w/ transparency)") {
                        if let out = resultImage {
                            ZStack {
                                Checkerboard()
                                Image(uiImage: out)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(8)
                            }
                            .frame(maxHeight: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            // Permission-aware save + Share fallback
                            VStack(spacing: 8) {
                                Button {
                                    Task { await ensurePermissionThenSave(out) }
                                } label: {
                                    Label("Save to Photos", systemImage: "photo.badge.arrow.down")
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.borderedProminent)

                                Button {
                                    shareItem = out
                                    showShare = true
                                } label: {
                                    Label("Share / Export", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.bordered)

                                // Tiny status row
                                HStack(spacing: 6) {
                                    switch photosStatus {
                                    case .authorized, .limited:
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                        Text("Photos access granted")
                                            .foregroundColor(.secondary).font(.footnote)
                                    case .notDetermined:
                                        Image(systemName: "questionmark.circle").foregroundColor(.orange)
                                        Text("Permission needed to save")
                                            .foregroundColor(.secondary).font(.footnote)
                                    case .denied, .restricted:
                                        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                                        Button("Open Settings") { openSettings() }
                                            .font(.footnote)
                                    }
                                    Spacer()
                                }
                            }
                            .sheet(isPresented: $showShare) {
                                if let shareItem {
                                    ActivityView(activityItems: [shareItem])
                                }
                            }

                        } else {
                            Text("Your cutout will appear here.")
                                .foregroundColor(.secondary)
                        }
                    }

                    // ERROR
                    if let err = errorMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                            Text(err).font(.footnote)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 40)
                .alert(saveMessage, isPresented: $showSaveAlert) {
                    Button("OK", role: .cancel) {}
                }
            }
            .scrollIndicators(.visible)
            .background(
                LinearGradient(colors: [Color(.systemBackground),
                                        Color(.secondarySystemBackground)],
                               startPoint: .top, endPoint: .bottom)
            )
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
        // FILES
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let data = try Data(contentsOf: url)
                    if let img = UIImage(data: data) {
                        sourceImage = img
                        sourceFilename = url.lastPathComponent
                        errorMessage = nil
                    } else {
                        errorMessage = "Unsupported image file."
                    }
                } catch {
                    errorMessage = "Failed to open image: \(error.localizedDescription)"
                }
            case .failure(let err):
                errorMessage = "File selection error: \(err.localizedDescription)"
            }
        }
        // PHOTOS
        .onChange(of: selectedPhotoItem) { item in
            guard let item else { return }
            Task { await loadFromPhotos(item) }
        }
        .onAppear {
            photosStatus = currentAddStatus()
        }
    }

    // MARK: - Photos loader (Data path)
    private func guessFilename(from item: PhotosPickerItem) -> String {
        if let id = item.itemIdentifier { return id + ".jpg" }
        return "photo.jpg"
    }

    private func loadFromPhotos(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                sourceImage = img
                sourceFilename = guessFilename(from: item)
                errorMessage = nil
                return
            }
            throw NSError(domain: "BEN2", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: "Could not read selected photo."])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - API call
    private func runRemoval() async {
        guard let sourceImage else { return }
        do {
            isBusy = true; errorMessage = nil

            guard let jpeg = sourceImage.jpegData(compressionQuality: 0.9) else {
                throw NSError(domain: "BEN2", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "Could not encode JPEG"])
            }

            let filename = sourceFilename.isEmpty ? "image.jpg" : sourceFilename
            
            let client = BEN2Client.shared
            
            let pngBytes = try await client.removeBackground(image: sourceImage,
                                                             filename: sourceFilename.isEmpty ? "image.jpg" : sourceFilename,
                                                             jpegQuality: 0.9)

            guard let out = UIImage(data: pngBytes) else {
                throw NSError(domain: "BEN2", code: -3,
                              userInfo: [NSLocalizedDescriptionKey: "Server returned non-image data"])
            }
            resultImage = out
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    // MARK: - Permission-aware save
    private func ensurePermissionThenSave(_ img: UIImage) async {
        var status = currentAddStatus()
        if status == .notDetermined {
            status = await requestAddOnlyAccess()
            photosStatus = status
        }
        switch status {
        case .authorized, .limited:
            savePNG(img)
        case .denied, .restricted:
            saveMessage = "Photos permission denied. Enable in Settings → Privacy → Photos."
            showSaveAlert = true
        case .notDetermined:
            saveMessage = "Photos permission is required to save."
            showSaveAlert = true
        }
    }

    // MARK: - Save PNG to Photos
    private func savePNG(_ img: UIImage) {
        guard let pngData = img.pngData(),
              let pngImage = UIImage(data: pngData) else {
            errorMessage = "Could not create PNG data"
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: pngImage)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    saveMessage = "Saved to Photos ✅"
                } else {
                    saveMessage = "Save failed: \(error?.localizedDescription ?? "Unknown error")"
                }
                showSaveAlert = true
            }
        }
    }
}

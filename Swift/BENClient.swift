// BENClient.swift
import Foundation
import UIKit

public enum BEN2Error: Error, LocalizedError {
    case invalidResponse(Int, String)
    case notImage
    case encodeFailed
    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let code, let body): return "HTTP \(code): \(body)"
        case .notImage: return "Server returned non-image data"
        case .encodeFailed: return "Could not encode image"
        }
    }
}

public final class BEN2Client {
    public static let shared = BEN2Client(
        apiKey: Bundle.main.object(forInfoDictionaryKey: "BEN2_API_KEY") as? String ?? "YOUR_API_KEY"
    )

    private let apiKey: String
    private let baseURL = URL(string: "https://api.backgrounderase.net/v2")!
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: Public convenience (UIImage -> PNG bytes)
    public func removeBackground(image uiImage: UIImage,
                                 filename: String = "image.jpg",
                                 jpegQuality: CGFloat = 0.9,
                                 timeout: TimeInterval = 60) async throws -> Data {
        guard let data = uiImage.jpegData(compressionQuality: jpegQuality) else { throw BEN2Error.encodeFailed }
        return try await removeBackground(imageData: data, filename: filename, timeout: timeout)
    }

    // MARK: Core uploader (arbitrary Data)
    public func removeBackground(imageData: Data,
                                 filename: String,
                                 timeout: TimeInterval = 60) async throws -> Data {

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout

        let boundary = "----BEN2-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let mime = Self.mimeType(for: filename)
        let body = Self.multipartBody(
            name: "image_file",
            filename: filename,
            mimeType: mime,
            fileData: imageData,
            boundary: boundary
        )
        request.httpBody = body
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "<no body>"
            throw BEN2Error.invalidResponse(http.statusCode, msg)
        }
        return data // raw PNG bytes
    }

    // MARK: Helpers
    private static func mimeType(for filename: String) -> String {
        switch (filename as NSString).pathExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png":         return "image/png"
        case "heic":        return "image/heic"
        case "webp":        return "image/webp"
        default:            return "application/octet-stream"
        }
    }

    private static func multipartBody(name: String,
                                      filename: String,
                                      mimeType: String,
                                      fileData: Data,
                                      boundary: String) -> Data {
        let CRLF = "\r\n"
        var data = Data()
        data.append("--\(boundary)\(CRLF)".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\(CRLF)".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\(CRLF)\(CRLF)".data(using: .utf8)!)
        data.append(fileData)
        data.append("\(CRLF)--\(boundary)--\(CRLF)".data(using: .utf8)!)
        return data
    }
}

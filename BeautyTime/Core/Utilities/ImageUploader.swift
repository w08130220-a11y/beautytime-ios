import Foundation
import PhotosUI
import SwiftUI

enum ImageUploader {
    static func upload(
        data: Data,
        fileName: String = "image.jpg",
        contentType: String = "image/jpeg",
        endpoint: String = APIEndpoints.Portfolio.upload
    ) async -> String? {
        let base64 = data.base64EncodedString()
        let body = JSONBody([
            "fileName": fileName,
            "contentType": contentType,
            "fileData": base64
        ] as [String: Any])
        do {
            let response: ImageUploadResponse = try await APIClient.shared.post(
                path: endpoint,
                body: body
            )
            return response.url ?? response.imageUrl
        } catch {
            return nil
        }
    }

    static func loadAndUpload(
        item: PhotosPickerItem,
        fileName: String = "image.jpg",
        endpoint: String = APIEndpoints.Portfolio.upload
    ) async -> String? {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        return await upload(data: data, fileName: fileName, endpoint: endpoint)
    }
}

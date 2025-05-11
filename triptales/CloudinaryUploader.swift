import Foundation
import Cloudinary
import UIKit

class CloudinaryUploader {
    private let cloudinary: CLDCloudinary

    init() {
        let cloudName = Env.shared.get("CLOUDINARY_CLOUD_NAME") ?? ""
        let apiKey = Env.shared.get("CLOUDINARY_API_KEY") ?? ""
        let apiSecret = Env.shared.get("CLOUDINARY_API_SECRET") ?? ""

        assert(!cloudName.isEmpty, "Missing CLOUDINARY_CLOUD_NAME in .env")
        assert(!apiKey.isEmpty, "Missing CLOUDINARY_API_KEY in .env")
        assert(!apiSecret.isEmpty, "Missing CLOUDINARY_API_SECRET in .env")

        let config = CLDConfiguration(cloudName: cloudName, apiKey: apiKey, apiSecret: apiSecret)
        self.cloudinary = CLDCloudinary(configuration: config)
    }

    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Invalid image data", code: -1, userInfo: nil)))
            return
        }

        let params = CLDUploadRequestParams()
        params.setFolder("triptales")
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "triptales", params: params)
            .response { result, error in
                if let error = error {
                    completion(.failure(error))
                } else if let result = result, let url = result.secureUrl {
                    completion(.success(url))
                } else {
                    completion(.failure(NSError(domain: "Cloudinary upload failed", code: -1, userInfo: nil)))
                }
            }
    }
}

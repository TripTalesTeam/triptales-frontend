//
//  CloudinaryUploader.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 12/5/2568 BE.
//


import Foundation
import Cloudinary
import UIKit

class CloudinaryUploader {
    private let cloudinary: CLDCloudinary

    init() {
        // Get environment variables from ProcessInfo
        let cloudName = ProcessInfo.processInfo.environment["CLOUDINARY_CLOUD_NAME"] ?? ""
        let apiKey = ProcessInfo.processInfo.environment["CLOUDINARY_API_KEY"] ?? ""
        let apiSecret = ProcessInfo.processInfo.environment["CLOUDINARY_API_SECRET"] ?? ""

        // Ensure all values are present
        assert(!cloudName.isEmpty, "Cloudinary Cloud Name is missing!")
        assert(!apiKey.isEmpty, "Cloudinary API Key is missing!")
        assert(!apiSecret.isEmpty, "Cloudinary API Secret is missing!")

        // Initialize Cloudinary with the environment values
        let config = CLDConfiguration(cloudName: cloudName, apiKey: apiKey, apiSecret: apiSecret)
        self.cloudinary = CLDCloudinary(configuration: config)
    }

    // Upload image to Cloudinary and return the URL
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
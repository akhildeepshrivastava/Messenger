//
//  Storage.swift
//  Messenger
//
//  Created by Shweta Shrivastava on 12/30/20.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /image/myemail-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, StorageError>) -> Void
    /// Uploads picture to firebase storager and return url string to dopwnload
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { (metaData, error) in
            guard error == nil else {
                completion(.failure(.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url, error == nil else {
                    completion(.failure(.failedTogetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print(urlString)
                completion(.success(urlString))
            }
        }
    }
    
    public enum StorageError: Error {
        case failedToUpload
        case failedTogetDownloadUrl
    }
    
    public func downloadUrl(for path: String, completion: @escaping (Result<URL, StorageError>) -> Void) {
        let referecne = storage.child(path)
        referecne.downloadURL { (url, error) in
            guard let imageUrl = url, error == nil else {
                print("Can'rt find image URL")
                completion(.failure(.failedTogetDownloadUrl))
                return
            }
            
            completion(.success(imageUrl))
        }
    }
    
    /// Uploads image that is sent in conversation
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { (metaData, error) in
            guard error == nil else {
                completion(.failure(.failedToUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL { (url, error) in
                guard let url = url, error == nil else {
                    completion(.failure(.failedTogetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print(urlString)
                completion(.success(urlString))
            }
        }
    }
    
    
    /// Uploads video that is sent in conversation
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] (metaData, error) in
            guard error == nil else {
                completion(.failure(.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL { (url, error) in
                guard let url = url, error == nil else {
                    completion(.failure(.failedTogetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print(urlString)
                completion(.success(urlString))
            }
        }
    }
}

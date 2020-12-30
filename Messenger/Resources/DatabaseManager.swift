//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Shweta Shrivastava on 12/29/20.
//

import Foundation
import FirebaseDatabase

final class DataBaseManager {
    static let shared = DataBaseManager()
    
    private let database = Database.database().reference()
}

extension DataBaseManager {
    
    /// insert new user to database
    public func inserUser(with user: ChatAppUser) {
        
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
    
    /// check if user already exists
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard let _ = snapshot.value as? String else {
                completion(false)
                return
            }
            completion(true)
        }
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
//    let profilePictureUrl: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

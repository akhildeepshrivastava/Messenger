//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Shweta Shrivastava on 12/29/20.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DataBaseManager {
    static let shared = DataBaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DataBaseManager {
    
    /// insert new user to database
    public func inserUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    usersCollection.append([
                        "name": "\(user.firstName) \(user.lastName)",
                        "email": user.safeEmail
                    ])
                    
                    self.database.child("users").setValue(usersCollection) { (error, _) in
                        guard error == nil else {
                            print("Modified users - Failed")
                            completion(false)
                            return
                        }
                        print("Modified users - Success")
                        completion(true)
                    }
                    
                } else {
                    let newCollection: [[String: String]] = [
                        [
                            "name": "\(user.firstName) \(user.lastName)",
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection) { (error, _) in
                        guard error == nil else {
                            print("Created new user - Failed")
                            completion(false)
                            return
                        }
                        print("Created new user - Success")
                        completion(true)
                    }
                }
                
            }
        }
    }
    
    /// check if user already exists
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DataBaseManager.safeEmail(email: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
//            completion(snapshot.exists())
            guard let _ = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///
    public func getAUsers(completion: @escaping (Result<[[String: String]], DataBaseError>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snalshot) in
            guard let value = snalshot.value as? [[String: String]] else {
                completion(.failure(.failedTopFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
    public func conversationExists(with targetRecipientEmail: String, completiuon: @escaping (Result<String, DataBaseError>) -> Void) {
        let safeRecipientEmail = DataBaseManager.safeEmail(email: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DataBaseManager.safeEmail(email: senderEmail)
        
        database.child("\(safeSenderEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completiuon(.failure(.failedTopFetch))
                return
            }
            
            if let conversation = value.first(where: {
                guard let targteUserEmail = $0["otherUserEmail"] as? String else {
                    return false
                }
                return safeSenderEmail == targteUserEmail
            }) {
                guard let id = conversation["id"] as? String else {
                    completiuon(.failure(.failedTopFetch))
                    return
                }
                completiuon(.success(id))
                return
            }
            
            completiuon(.failure(.failedTopFetch))
            return
        }
    }

}

// MARK: - Sending Messages/Conversation
extension DataBaseManager {
    
    private func finishCreatingCopnversation(name: String, conversationID: String, firsMessage: Message, completion: @escaping (Bool) -> Void) {
        
        guard let currentUserEmial = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let safeEmail = DataBaseManager.safeEmail(email: currentUserEmial)
        
        let messageDate = firsMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var messgge = ""
        switch firsMessage.kind {
        
        case .text(let messageText):
            messgge = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let collectionMessage: [String: Any] = [
            "id": firsMessage.messageId,
            "type": firsMessage.kind.messageType,
            "content": messgge,
            "date": dateString,
            "sender_email": safeEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "message" : [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value) { (error, ref) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
     
    /// Create a new conversation with trageted user email and first messge
    public func createNewConversation(with otherEmail: String, firsMessage: Message, name: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserEmial = UserDefaults.standard.value(forKey: "email") as? String, let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        
        
        let safeEmail = DataBaseManager.safeEmail(email: currentUserEmial)
        let ref =  database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) {[weak self] (snapshot) in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firsMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var messgge = ""
            switch firsMessage.kind {
            
            case .text(let messageText):
                messgge = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation_\(firsMessage.messageId)"
            let newConversation: [String: Any] = [
            
                "id":  conversationId,
                "otherUserEmail": otherEmail,
                "name": name,
                "latestMessage": [
                    "date": dateString,
                    "message": messgge,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversation: [String: Any] = [
            
                "id":  conversationId,
                "otherUserEmail": safeEmail,
                "name": currentName,
                "latestMessage": [
                    "date": dateString,
                    "message": messgge,
                    "is_read": false
                ]
            ]
            
            //Update recipient conversation Entry
            self?.database.child("\(otherEmail)/conversations").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                if var conversations = snapshot.value as? [[String: Any]] {
                    conversations.append(recipient_newConversation)
                    self?.database.child("\(otherEmail)/conversations").setValue(conversations)
                } else {
                    self?.database.child("\(otherEmail)/conversations").setValue([recipient_newConversation])
                }
            }
            
            
            
            //Update Current User Conversation Entry
            if var conversation = userNode["conversations"] as? [[String:Any]] {
                conversation.append(newConversation)
                userNode["conversations"] = conversation
                ref.setValue(userNode) { [weak self](error, dbRef) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingCopnversation(name: name, conversationID: conversationId, firsMessage: firsMessage, completion: completion)
                }
            } else {
                userNode["conversations"] = [
                    newConversation
                ]
                ref.setValue(userNode) { [weak self] (error, dbRef) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingCopnversation(name: name, conversationID: conversationId, firsMessage: firsMessage, completion: completion)
                }
            }
        }
    }
    
    /// Fetcheds all conversation for the user with passed in email
    public func getAllConversation(for email: String, completion: @escaping (Result<[Conversation], DataBaseError>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(.failedTopFetch))
                return
            }

            let conversations: [Conversation] = value.compactMap { (dictonary) in
                guard let conversationId = dictonary["id"] as? String,
                      let name = dictonary["name"] as? String,
                      let otherUserEmail = dictonary["otherUserEmail"] as? String,
                      let latest_Message = dictonary["latestMessage"] as? [String: Any],
                      let sent = latest_Message["date"] as? String,
                      let message = latest_Message["message"] as? String,
                      let is_read = latest_Message["is_read"] as? Bool else {
                    let conversastion  = [Conversation]()
                    completion(.success(conversastion))
                    return nil
                }
                
                let latestMessage = LatestMessage(date: sent, message: message, is_read: is_read)
                let conversastion = Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessage)
                
                return conversastion
            }
            
            completion(.success(conversations))
        }
        
    }
    
    /// get all messages for gven conversation
    public func getAllMessageforConversation(with id: String, completion: @escaping (Result<[Message], DataBaseError>) -> Void) {
        database.child("\(id)/message").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(.failedTopFetch))
                return
            }
        
            let messages: [Message] = value.compactMap { (dictonary) in
                guard let name = dictonary["name"] as? String,
                      let isRead = dictonary["is_read"] as? Bool,
                      let messageId = dictonary["id"] as? String,
                      let content = dictonary["content"] as? String,
                      let senderEmail = dictonary["sender_email"] as? String,
                      let dateString = dictonary["date"] as? String,
                      let type = dictonary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)else {
                    return nil
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageURL  = URL(string: content), let placeHiolder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageURL, image: nil, placeholderImage: placeHiolder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    guard let videoUrl  = URL(string: content), let placeHiolder = UIImage(systemName: "play.rectangle.fill") else {
                        return nil
                    }
                    let media = Media(url: videoUrl, image: nil, placeholderImage: placeHiolder, size: CGSize(width: 300, height: 300))
                    
                    kind = .video(media)
                }else {
                    kind = .text(content)
                }
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            }
            
            completion(.success(messages))
        }
        
    }
    
    /// Sends a message with tragated conbversaion and message
    public func sendMessage(to conversation: String, name: String, messge newMessage: Message, otherUserEmail: String, completion: @escaping (Bool) -> Void) {
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return

        }
        let currentEmail = DataBaseManager.safeEmail(email: myEmail)
        
        self.database.child("\(conversation)/message").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self,  var currentMessage = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            guard let currentUserEmial = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let safeEmail = DataBaseManager.safeEmail(email: currentUserEmial)
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var messgge = ""
            switch newMessage.kind {
            
            case .text(let messageText):
                messgge = messageText
            case .attributedText(_):
                break
            case .photo(let media):
                if let targerUrl = media.url?.absoluteString {
                    messgge = targerUrl
                }
            case .video(let media):
                if let targerUrl = media.url?.absoluteString {
                    messgge = targerUrl
                }
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageType,
                "content": messgge,
                "date": dateString,
                "sender_email": safeEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessage.append(newMessageEntry)
            
            
            strongSelf.database.child("\(conversation)/message").setValue(currentMessage) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                
                }
                
                //update sender latest message
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    if let currentConversations = snapshot.value as? [[String: Any]]  {
                        
                        completion(false)
                        return
                    }
                    
                    
                    
                }
                
                
                // update recipient latest message
                strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    var dataBaseEntryConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = ["date": dateString, "is_read": false, "message": messgge]
                    
                    if var currentConversations = snapshot.value as? [[String: Any]]  {
                        
                        var targateedConversation: [String: Any]?
                        var position = 0
                        for currentConversation in currentConversations {
                            if let currentId = currentConversation["id"] as? String, currentId == conversation {
                                targateedConversation = currentConversation
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConversation = targateedConversation {
                            targetConversation["latestMessage"] = updatedValue
                            currentConversations[position] = targetConversation
                            dataBaseEntryConversations = currentConversations
                        } else {
                            let newConversation: [String: Any] = [
                            
                                "id":  conversation,
                                "otherUserEmail": DataBaseManager.safeEmail(email: otherUserEmail),
                                "name": name,
                                "latestMessage": updatedValue
                            ]
                            currentConversations.append(newConversation)
                            dataBaseEntryConversations = currentConversations
                        }
                        
                    } else {
                        let newConversation: [String: Any] = [
                        
                            "id":  conversation,
                            "otherUserEmail": DataBaseManager.safeEmail(email: otherUserEmail),
                            "name": name,
                            "latestMessage": updatedValue
                        ]
                        
                        dataBaseEntryConversations = [
                            newConversation
                        ]
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(dataBaseEntryConversations) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }

                }
            }
            
        }
    }
    
    public func deleteConversation(conId: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DataBaseManager.safeEmail(email: email)
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            if var conversations = snapshot.value as? [[String: Any]]  {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conId {
                        print("Found conversation to delete")

                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { (error, _) in
                    guard error == nil else {
                        print("Failed to delete conversation")
                        completion(false)
                        return
                    }
                    print("Success to delete conversation")
                    completion(true)
                }
            }
        }
        
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictrueFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}

public enum DataBaseError: Error {
    case failedTopFetch
}


extension DataBaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else {
                completion(.failure(DataBaseError.failedTopFetch))
                return
            }
            
            completion(.success(value))
        }
    }
}

//
//  ChatViewController.swift
//  Messenger
//
//  Created by Shweta Shrivastava on 12/30/20.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

extension MessageKind {
    var messageType: String {
        switch self {
       
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "attributedText"
        case .emoji(_):
            return "attributedText"
        case .audio(_):
            return "attributedText"
        case .contact(_):
            return "attributedText"
        case .linkPreview(_):
            return "attributedText"
        case .custom(_):
            return "attributedText"
        }
    }
}

struct Sender: SenderType {

    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUSerEmail: String
    public let conversationId: String?

    private var  messages = [Message]()
    
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DataBaseManager.safeEmail(email: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }
    
    init(with email: String, id: String?) {
        self.otherUSerEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        setUpInputButton()
    }
    
    private func setUpInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] (_) in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "what would you like to attach", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {  _ in
            
        }))
    
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "where would you like to attach a photo from", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
    
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)

    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DataBaseManager.shared.getAllMessageforConversation(with: id) {[weak self] (result) in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
            case .failure(let error):
                print("Erro Loading conversation")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            self.listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = selfSender, let messsageID = createMessageID() else {
            return
        }
        
        messageInputBar.inputTextView.text = ""
        print("Sending \(text)")
        let message = Message(sender: selfSender, messageId: messsageID, sentDate: Date(), kind: .text(text))

        if isNewConversation {
            DataBaseManager.shared.createNewConversation(with: otherUSerEmail, firsMessage: message, name: self.title ??  "") { [weak self] (success) in
                if success {
                    self?.isNewConversation = false
                    print("message sent")
                } else {
                    print("Fialed to send")
                }
            }
        } else {
            
            guard let id = self.conversationId, let name = self.title else {
                return
            }
            DataBaseManager.shared.sendMessage(to: id, name: name, messge: message, otherUserEmail: otherUSerEmail) { (success) in
                if success {
                    print("message sent")
                } else {
                    print("Fialed to send")
                }
            }
        }
    }
    
    private func createMessageID() -> String?  {
        // date, otherUserEmail, SenderEmail, randomInt
        let dateString = Self.dateFormatter.string(from: Date())
        guard let currentUserEmial = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DataBaseManager.safeEmail(email: currentUserEmial)
        let newIdentifier = "\(otherUSerEmail)_\(safeEmail)_\(dateString)"
        return newIdentifier
    }
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageurl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageurl, completed: nil)
        default:
            break
        }
    }

}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageurl = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: imageurl)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}


extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let imageData = image.pngData(), let messageId = createMessageID(), let conversationId = conversationId, let name = self.title, let selfSender = selfSender else {
            return
        }
        
        let fileName = "photo_message_\(messageId.replacingOccurrences(of: " ", with: "-")).png"
        //Upload Image
        StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let urlString):
                print("Uoploaded Messgage Photo \(urlString)")
                guard let url = URL(string: urlString), let placeHolder = UIImage(systemName: "plus") else {
                    return
                }
                let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(media))

                
                DataBaseManager.shared.sendMessage(to: conversationId, name: name, messge: message, otherUserEmail: strongSelf.otherUSerEmail) { (success) in
                    picker.dismiss(animated: true, completion: nil)
                    if success {
                        self?.isNewConversation = false
                        print("photo message sent")
                    } else {
                        print("photo message failed")
                    }
                }
            case .failure(let error):
                print("messagfe photo upload failed: \(error)")
            }
        }
        
    }
}

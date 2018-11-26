//
//  ChatController.swift
//  stormchat
//
//  Created by Gautam Baghel on 11/21/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import Foundation
import UIKit
import MessageKit


struct Message : Codable {
    var id: Int
    var userid: Int
    var username: String
    var body: String
    var time: String
}

struct jsonData : Codable {
    let data: [Message]
}

var messages: [Message] = []

class ChatController: MessagesViewController {

    var alert_id:String = ""
    var headline:String = ""
    var event:String = ""
    var username = ""
    var userId = ""
    var token = ""
    var messages = [Message]()
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        self.navigationItem.title = self.event
        
        // Get user info
        if let data = UserDefaults.standard.object(forKey: "currentUser"),
            let json = self.convertToDictionary(text: data as! String) {
            
            if let username = json["name"],
               let token = json["token"] {
                
                self.token = "\(token)"
                self.username = "\(username)"
            }
            
            // Keep this if stmt above the below one
            // Cos the auth token (fb/google) contains user_id as well
            // but the stormchat DB token doesn't contain auth_id
            if let user_id = json["user_id"] {
                self.userId = "\(user_id)"
            }
            
            if let auth_id = json["auth_id"] {
                self.userId = "\(auth_id)"
            }
            
            
        } else {
            self.segueToLoginController()
        }

        
        // Call every second to get messages
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ChatController.loadMessages), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func segueToLoginController() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let loginController:ViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.present(loginController, animated: true, completion: nil)
    }

}

extension Message: MessageType {
    var messageId: String {
        return "\(id)"
    }
    
    var sender: Sender {
        return Sender(id: "\(userid)", displayName: username)
    }
    
    var sentDate: Date {
        return Date()
    }
    
    var kind: MessageKind {
        return .text(body)
    }
}

extension ChatController: UINavigationBarDelegate {
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension ChatController: MessagesDataSource {
    func numberOfSections(
        in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func currentSender() -> Sender {
        return Sender(id: userId, displayName: username)
    }
    
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
    }
    
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 12
    }
    
    func messageTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath) -> NSAttributedString? {
        
        return NSAttributedString(
            string: message.sender.displayName,
            attributes: [.font: UIFont.systemFont(ofSize: 12)])
    }
}

extension ChatController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType,
                           at indexPath: IndexPath,
                           with maxWidth: CGFloat,
                           in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 0
    }
}

extension ChatController: MessagesDisplayDelegate {
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) {

        let message = messages[indexPath.section]
        let initial = "\(String(describing: message.username.first!))"
        avatarView.initials = initial.capitalized
    }
}


extension ChatController: MessageInputBarDelegate {
    func messageInputBar(
        _ inputBar: MessageInputBar,
        didPressSendButtonWith text: String) {
        
        inputBar.inputTextView.resignFirstResponder()
        
        let location = "https://stormchat.gautambaghel.com/api/v1/posts/mobile/" + self.alert_id
        let url = URL(string: location)!
        
        let headers = [
            "content-type": "application/json",
            "cache-control": "no-cache",
            "postman-token": "b393c5ad-6421-2115-37fd-dd70924904e3"
        ]
        let parameters = [
            "token": self.token,
            "post": [
                "user_id": self.userId,
                "alert": self.alert_id,
                "body": text
             ]
            ] as [String : Any]
        
        var postData: Data?
        do {
            postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print(error.localizedDescription)
        }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "Post Error")
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse ?? "HTTP response")
            }
        })
        
        dataTask.resume()
        inputBar.inputTextView.text = ""
    }
}

// MARK: - Navigation
extension ChatController{
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "chatInfoSegue" {
            
            if let nav = segue.destination as? UINavigationController,
               let chatInfoController = nav.topViewController as? InfoController {
                
                chatInfoController.headline = headline
                chatInfoController.event = event
            }
        }
     }
}


// MARK: - Helper Functions
extension ChatController {
    
    @objc func loadMessages(){
        let location = "https://stormchat.gautambaghel.com/api/v1/posts/" + self.alert_id
        let url = URL(string: location)!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(jsonData.self, from: data)
                let msgs: [Message] = response.data
                
                if self.messages.count != msgs.count {
                    self.messages.removeAll()
                    self.addMessages(messages: msgs)
                }
                
            } catch { print(error) }
            
        }
        task.resume()
    }
    
    func addMessages(messages: [Message]) {
        self.messages.append(contentsOf: messages)
        self.messages.sort(by: {
            if self.convertToDate(str: $1.time).compare(self.convertToDate(str: $0.time)) == ComparisonResult.orderedDescending {
                return true
            } else {
                return false
            }
        })
        
        DispatchQueue.main.async() {
            () -> Void in
            self.messagesCollectionView.reloadData()
            if self.messages.count > 0 {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    private func convertToDate(str: String) -> Date {
        let date = str.split(separator: "-")
        let year = date[0]
        let month = date[1]
        
        let dateSep = date[2].split(separator: "T")
        let day = dateSep[0]
        
        let timeSep = dateSep[1].split(separator: ".")
        let minSep = timeSep[0].split(separator: ":")
        let hour = minSep[0]
        let minute = minSep[1]
        let second = minSep[2]
        let nanosecond = timeSep[1]
        
        var dateComponents = DateComponents()
        dateComponents.year = Int(year)
        dateComponents.month = Int(month)
        dateComponents.day = Int(day)
        
        dateComponents.hour = Int(hour)
        dateComponents.minute = Int(minute)
        dateComponents.second = Int(second)
        dateComponents.nanosecond = Int(nanosecond)
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        let someDateTime = userCalendar.date(from: dateComponents)
        
        return someDateTime!
    }
}

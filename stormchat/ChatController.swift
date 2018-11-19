//
//  ChatController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/15/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit
import SlackTextViewController

struct Message : Codable {
    var id: Int
    var username: String
    var body: String
    var time: String
}

struct jsonData : Codable {
    let data: [Message]
}

class ChatController: SLKTextViewController {

    var id:String = ""
    var headline:String = ""
    var event:String = ""
    var userId = ""
    var token = ""
    var messages = [Message]()
    var timer: Timer?
    
    @IBOutlet weak var navItem: UINavigationItem!

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    override var tableView: UITableView {
        get { return super.tableView! }
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
            self.tableView.reloadData()
            if self.messages.count > 0 {
                self.scrollToBottomMessage()
            }
        }
    }
    
    @objc private func loadMessages(){
        let location = "https://stormchat.gautambaghel.com/api/v1/posts/" + self.id
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
}

// MARK: UI Logic
// Scroll to bottom of table view for messages

extension ChatController {
    func scrollToBottomMessage() {
        if self.messages.count == 0 {
            return
        }
        let bottomMessageIndex = NSIndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1,
                                             section: 0)
        self.tableView.scrollToRow(at: bottomMessageIndex as IndexPath, at: .bottom,
                                              animated: true)
    }
}

// MARK: - Initialize -
extension ChatController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // self.subscribeToRoom()
        self.setNavigationItemTitle()
        self.configureSlackTableViewController()
        
        // Get user info
        if let data = UserDefaults.standard.object(forKey: "currentUser") {
            let val = self.convertToDictionary(text: data as! String)
            let userId = val!["auth_id"]!
            let token = val!["token"]!
            self.userId = "\(userId)"
            self.token = "\(token)"
        }
        
        // Call every second to get messages
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ChatController.loadMessages), userInfo: nil, repeats: true)
        
        self.loadMessages()
        self.tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "MessageTableViewCell")
    }
    
    
//    private func subscribeToRoom() -> Void {
//        self.currentUser.subscribeToRoom(room: self.room, roomDelegate: self)
//    }
    
    private func setNavigationItemTitle() -> Void {
        self.navigationItem.title = "asd"
        navItem.title = "asd"
        print(self.navigationItem)
    }
    
    private func configureSlackTableViewController() -> Void {
        self.bounces = true
        self.isInverted = false
        self.shakeToClearEnabled = true
        self.isKeyboardPanningEnabled = true
        self.textInputbar.maxCharCount = 256
        self.tableView.separatorStyle = .none
        self.textInputbar.counterStyle = .split
        self.textInputbar.counterPosition = .top
        self.textInputbar.autoHideRightButton = true
        self.textView.placeholder = "Enter Message...";
        self.shouldScrollToBottomAfterKeyboardShows = false
        self.textInputbar.editorTitle.textColor = UIColor.darkGray
        self.textInputbar.editorRightButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        // self.tableView.register(MessageCell.classForCoder(), forCellReuseIdentifier: MessageCell.MessengerCellIdentifier)
        // self.autoCompletionView.register(MessageCell.classForCoder(), forCellReuseIdentifier: MessageCell.AutoCompletionCellIdentifier)
    }
}

// MARK: - UITableViewController Overrides -
extension ChatController {
    override class func tableViewStyle(for decoder: NSCoder) -> UITableViewStyle {
        return .plain
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return self.messages.count
        }
        return 0
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // return self.messageCellForRowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as! MessageTableViewCell
        
        let message = self.messages[indexPath.row]
        
        cell.nameLabel.text = message.username
        cell.bodyLabel.text = message.body
        cell.selectionStyle = .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tableView {
            let message = self.messages[(indexPath as NSIndexPath).row]
            if message.body.count == 0 {
                return 0
            }
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .left
            let pointSize = MessageCell.defaultFontSize()
            let attributes = [
                NSAttributedStringKey.font: UIFont.systemFont(ofSize: pointSize),
                NSAttributedStringKey.paragraphStyle: paragraphStyle
            ]
            var width = tableView.frame.width - MessageCell.kMessageTableViewCellAvatarHeight
            width -= 25.0
            let titleBounds = (message.username as NSString?)?.boundingRect(
                with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
            let bodyBounds = (message.body as NSString?)?.boundingRect(
                with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
            var height = titleBounds!.height
            height += bodyBounds!.height
            height += 40
            if height < MessageCell.kMessageTableViewCellMinimumHeight {
                height = MessageCell.kMessageTableViewCellMinimumHeight
            }
            return height
        }
        return MessageCell.kMessageTableViewCellMinimumHeight
    }
}

// MARK: - Overrides -
extension ChatController {
    override func keyForTextCaching() -> String? {
        return Bundle.main.bundleIdentifier
    }
    override func didPressRightButton(_ sender: Any!) {
        self.textView.refreshFirstResponder()
        self.sendMessage(textView.text)
        super.didPressRightButton(sender)
    }
}

// MARK: - Delegate Methods -
extension ChatController {
    public func newMessage(msg: Message) {
        let indexPath = IndexPath(row: 0, section: 0)
        let rowAnimation: UITableViewRowAnimation = self.isInverted ? .bottom : .top
        let scrollPosition: UITableViewScrollPosition = self.isInverted ? .bottom : .top
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.messages.insert(msg, at: 0)
            self.tableView.insertRows(at: [indexPath], with: rowAnimation)
            // self.tableView.endUpdates()
            self.tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            self.tableView.reloadData()
        }
    }
}

// MARK: - Helpers -
extension ChatController {
    
    private func sendMessage(_ message: String) -> Void {
        
        let location = "https://stormchat.gautambaghel.com/api/v1/posts/mobile/" + self.id
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
                "alert": self.id,
                "body": message
            ]
        ] as [String : Any]
        
        var postData: Data?
        do {
            postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print(error.localizedDescription)
        }
        
        let request = NSMutableURLRequest(url: url,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
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
    // self.currentUser?.addMessage(text: message, to: room, completionHandler: { (messsage, error) in
    //   guard error == nil else { return }
    // })
        
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
    
    private func messageCellForRowAtIndexPath(_ indexPath: IndexPath) -> MessageCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: MessageCell.MessengerCellIdentifier) as! MessageCell
        let message = self.messages[(indexPath as NSIndexPath).row]
        cell.bodyLabel().text = message.body
        cell.titleLabel().text = message.username
        cell.usedForMessage = true
        cell.indexPath = indexPath
        cell.transform = self.tableView.transform
        return cell
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


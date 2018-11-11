//
//  ChatController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/15/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit
import SlackTextViewController

class ChatController: SLKTextViewController {

    var id:String = ""
    var headline:String = ""
    var event:String = ""
    var messages = [Message]()
    
    @IBOutlet weak var navItem: UINavigationItem!
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        display.text = id + headline + event
//        // Do any additional setup after loading the view.
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override var tableView: UITableView {
        get { return super.tableView! }
    }
    
    func loadMessages() {
        self.messages.removeAll()
        let messages = [Message(id: 1, username: "bob", text: "My Nigga Bob", timestamp: "asd")]
        self.addMessages(messages: messages)
    }
    
    func addMessages(messages: [Message]) {
        self.messages.append(contentsOf: messages)
        self.messages.sort(by: { $1.timestamp.count > $0.timestamp.count })
        
        DispatchQueue.main.async() {
            () -> Void in
            self.tableView.reloadData()
            if self.messages.count > 0 {
                self.scrollToBottomMessage()
            }
        }
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
//      self.subscribeToRoom()
        self.setNavigationItemTitle()
        self.configureSlackTableViewController()
        
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
//        self.tableView.register(MessageCell.classForCoder(), forCellReuseIdentifier: MessageCell.MessengerCellIdentifier)
//        self.autoCompletionView.register(MessageCell.classForCoder(), forCellReuseIdentifier: MessageCell.AutoCompletionCellIdentifier)
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
        //return self.messageCellForRowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as! MessageTableViewCell
        
        let message = self.messages[indexPath.row]
        
        cell.nameLabel.text = message.username
        cell.bodyLabel.text = message.text
        cell.selectionStyle = .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tableView {
            let message = self.messages[(indexPath as NSIndexPath).row]
            if message.text.count == 0 {
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
            let bodyBounds = (message.text as NSString?)?.boundingRect(
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
    private func SCMessageToMessage(_ message: SCMessage) -> Message {
        return Message(id: message.id, username: message.username, text: message.text, timestamp: message.timestamp)
    }
    private func sendMessage(_ message: String) -> Void {
        let msg = Message(id: 2, username: "Dave", text: "My Nigga Dave", timestamp: "asda")
        messages.append(msg)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.slk_scrollToBottom(animated: true)
        }
//        self.currentUser?.addMessage(text: message, to: room, completionHandler: { (messsage, error) in
//            guard error == nil else { return }
//        })
    }
    private func messageCellForRowAtIndexPath(_ indexPath: IndexPath) -> MessageCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: MessageCell.MessengerCellIdentifier) as! MessageCell
        let message = self.messages[(indexPath as NSIndexPath).row]
        cell.bodyLabel().text = message.text
        cell.titleLabel().text = message.username
        cell.usedForMessage = true
        cell.indexPath = indexPath
        cell.transform = self.tableView.transform
        return cell
    }
}

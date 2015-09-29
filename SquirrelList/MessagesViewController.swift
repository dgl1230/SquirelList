//
//  MessagesViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class MessagesViewController: JSQMessagesViewController {

    deinit {
        //We remove the observers for reloading the controller
        NSNotificationCenter.defaultCenter().removeObserver(self, name: reloadNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "reloadmessages", object: nil)
    }

    var group: PFObject!
    var incomingUser: PFUser!
    var users = [String]()
    
    var messages = [JSQMessage]()
    var messageObjects = [PFObject]()
    
    var outgoingBubbleImage: JSQMessagesBubbleImage!
    var incomingBubbleImage : JSQMessagesBubbleImage!
    
    //Variable for storing whether the viewcontroller should load new messages (if the user has received silent push notifications from other users)
    var shouldLoadNewMessages = false
    //Variable for determining whether the user changed new groups (and thus whether we should reload all messages)
    var shouldReload = false
    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let message = PFObject(className: "Messages")
        message["message"] = text
        message["group"] = PFUser.currentUser()!["currentGroup"] as? PFObject
        message["sender"] = PFUser.currentUser()!.username
        message.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if error == nil {
                self.loadMessages()
                //Send silent push notifications for other users to have their Messages tab refresh
                sendPushNotifications(0, message: "", type: "reloadMessages", users: PFUser.currentUser()!["currentGroup"]!["users"] as! [String])
            }
        }
        self.finishSendingMessage()
    }
    
    
    func loadMessages() {
        var lastMessage: JSQMessage?
        if messages.last != nil {
            lastMessage = messages.last
        }
        let messageQuery = PFQuery(className: "Messages")
        messageQuery.whereKey("group", equalTo: PFUser.currentUser()!["currentGroup"]!)
        messageQuery.orderByDescending("createdAt")
        messageQuery.limit = 30
        if lastMessage != nil {
            messageQuery.whereKey("createdAt", greaterThan: lastMessage!.date)
        }
        messageQuery.findObjectsInBackgroundWithBlock { (results: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                let messageResults = results as? [PFObject]
                let newMessages = Array(messageResults!.reverse())
                for message in newMessages {
                    self.messageObjects.append(message)
                    let user = message["sender"] as! String
                    self.users.append(user)
                    let chatMessage = JSQMessage(senderId: user, senderDisplayName: user, date: message.createdAt!, text: message["message"]! as! String)
                    self.messages.append(chatMessage)
                }
                
                if results!.count > 0 {
                    self.finishReceivingMessage()
                }

                self.finishReceivingMessage()
            } 
        }
    }
    
    
    
    func reload() {
        self.messages = []
        self.messageObjects = []
        self.users = []
        //This is goign to lead to lagging eventually, since this will mean that as soon as a user changes current groups, they will also be reloading messages, but it does prevent the array out of index error
        loadMessages()
    }
    
    //If the user is on the chat screen, we call loadMessages, since this function is only for live chat
    func loadNewMessages() {
        if self.view.window != nil {
            //We only want to load the newest messages via push notifications if the user is on the chat tab
            loadMessages()
        }
    }
    
    //For when I can figure out how not to get an array out of index error
    override func viewWillAppear(animated: Bool) {
        loadMessages()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //Listen for when a user has pushed a new silent notification (meaning they have sent a message in the group chat)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadNewMessages", name: "reloadMessages", object: nil)
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload", name: reloadNotificationKey, object: nil)
        //The sender ID doesn't have to be an actual ID, just something unique, so the user's username works too 
        self.senderId = PFUser.currentUser()!.username
        self.senderDisplayName = PFUser.currentUser()!.username
        //Disable the attachment button
        self.inputToolbar!.contentView!.leftBarButtonItem = nil
        
        let lightBlue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
        self.collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImage = bubbleFactory.outgoingMessagesBubbleImageWithColor(lightBlue)
        incomingBubbleImage = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.orangeColor())
        
        //For when the user touches an obscure area of the view
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "close")
        view.addGestureRecognizer(tap)
        
        self.collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        self.collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        self.collectionView!.collectionViewLayout.springinessEnabled = false
    }
    
    //For when the user touches an obscure area of the view we want to dismiss the keyboard
    func close() {
        view.endEditing(true)
    }
    

    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        if message.senderId != self.senderId {
            //Add the date sent to part of the attributedText
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.LongStyle
            formatter.timeStyle = .ShortStyle
            let date = formatter.stringFromDate(message.date)
            let displayInfo = "\(message.senderDisplayName) - \(date)"
            return NSMutableAttributedString(string: displayInfo)
        }
        return nil
    }


    
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as? JSQMessagesCollectionViewCell
        cell!.textView!.textColor = UIColor.blackColor()
        //Check to see if we are displaying a sender's name. If we are, we want their name to be aligned witht the beggining of the message
        let message = messages[indexPath.row]
        if message.senderId != self.senderId {
            cell!.messageBubbleTopLabel!.textInsets.left = 15.0
        }
        cell!.textView!.linkTextAttributes = [NSForegroundColorAttributeName:cell!.textView!.textColor!]
        return cell!
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        view.endEditing(true)
        
    }
    
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
            let message = messages[indexPath.row]
            if message.senderId != self.senderId {
                    return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
            return 0
        }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.row]
        
        if message.senderId == self.senderId {
            return outgoingBubbleImage
        }
        return incomingBubbleImage
    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    

}

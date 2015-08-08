//
//  MessagesViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class MessagesViewController: JSQMessagesViewController {

    var group: PFObject!
    var incomingUser: PFUser!
    var users = [String]()
    
    var messages = [JSQMessage]()
    var messageObjects = [PFObject]()
    
    var outgoingBubbleImage: JSQMessagesBubbleImage!
    var incomingBubbleImage : JSQMessagesBubbleImage!
    
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    //Optional for
    var firstViewDidLoad: Bool?
    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let message = PFObject(className: "Messages")
        message["message"] = text
        message["group"] = PFUser.currentUser()!["currentGroup"] as? PFObject
        message["senderNew"] = PFUser.currentUser()
        message["sender"] = PFUser.currentUser()!.username
        message.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if error == nil {
                self.loadMessages()
                
                let pushQuery = PFInstallation.query()
                
                //We want to get all installations that have the same users that are in the user's currentGroup
                pushQuery?.whereKey("username", containedIn: PFUser.currentUser()!["currentGroup"]!["users"] as! [String])
                
                let push = PFPush()
                push.setQuery(pushQuery)
                //We want silent push notifications
                let pushDict = ["alert": "", "badge":0, "sounds":"", "content-available": 1]
                push.setData(pushDict)
                push.sendPushInBackgroundWithBlock(nil)
                
            }
        }
        self.finishSendingMessage()
    }
    
    
    func loadMessages() {
        var lastMessage: JSQMessage? = nil
        
        if messages.last != nil {
            lastMessage = messages.last
        }
        let messageQuery = PFQuery(className: "Messages")
        messageQuery.whereKey("group", equalTo: PFUser.currentUser()!["currentGroup"]!)
        messageQuery.orderByAscending("createdAt")
    
        if lastMessage != nil {
            messageQuery.whereKey("createdAt", greaterThan: lastMessage!.date)
        }
        
        messageQuery.findObjectsInBackgroundWithBlock { (results: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                let messageResults = results as? [PFObject]
                for message in messageResults! {
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
            } else {
                println("error")
            }
        }
    }
    
    func reloadMessages() {
        loadMessages()
    }
    
    
    //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        self.messages = []
        self.messageObjects = []
        self.users = []
        //This is goign to lead to lagging eventually, since this will mean that as soon as a user changes current groups, they will also be reloading messages, but it does prevent the array out of index error
        loadMessages()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //Listen for when a user has pushed a new notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadMessages", name: "reloadMessages", object: nil)
        loadMessages()
        
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        //We only want the chat to get updated in real time if the user is on the chat screen
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "reloadMessages", object: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        firstViewDidLoad = true
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
        //The sender ID doesn't have to be an actual ID, just something unique, so the user's username works too 
        self.senderId = PFUser.currentUser()!.username
        self.senderDisplayName = PFUser.currentUser()!.username
        //Disable the attachment button
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        let lightBlue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
        
        let selfUsername = PFUser.currentUser()!.username! as NSString
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImage = bubbleFactory.outgoingMessagesBubbleImageWithColor(lightBlue)
        incomingBubbleImage = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.orangeColor())
        
        //For when the user touches an obscure area of the view
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "close")
        view.addGestureRecognizer(tap)
        
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;

    }
    
    //For when the user touches an obscure area of the view
    func close() {
        view.endEditing(true)
    }

    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        if message.senderId != self.senderId {
            let NSMessage = message.senderId as NSString
            if indexPath.item % 3 == 0 {
                return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
            }
            return NSMutableAttributedString(string: message.senderDisplayName)
        }
        return nil
    }

    
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as? JSQMessagesCollectionViewCell
        cell!.textView.textColor = UIColor.blackColor()
        //Check to see if we are displaying a sender's name. If we are, we want their name to be aligned witht the beggining of the message
        let message = messages[indexPath.row]
        if message.senderId != self.senderId {
            cell!.messageBubbleTopLabel.textInsets.left = 15.0
        }
        cell!.textView.linkTextAttributes = [NSForegroundColorAttributeName:cell!.textView.textColor]
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

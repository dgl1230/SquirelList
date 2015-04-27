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
    var users = [PFUser]()
    
    var messages = [JSQMessage]()
    var messageObjects = [PFObject]()
    
    var outgoingBubbleImage: JSQMessagesBubbleImage!
    var incomingBubbleImage : JSQMessagesBubbleImage!
    
    var selfAvatar: JSQMessagesAvatarImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let message = PFObject(className: "Messages")
        message["message"] = text
        message["group"] = PFUser.currentUser()!["currentGroup"] as? PFObject
        message["senderNew"] = PFUser.currentUser()
        message.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if error == nil {
                self.loadMessages()
                let pushQuery = PFInstallation.query()
                
                //We want to get all installations that have the same userID's that are in the user's currentGroup
                pushQuery?.whereKey("userID", containedIn: PFUser.currentUser()!["currentGroup"]!["userIDs"] as! [String])
                
                let push = PFPush()
                push.setQuery(pushQuery)
                
                let pushDict = ["alert": text, "badge":"increment", "sounds":""]
                push.setData(pushDict)
                push.sendPushInBackgroundWithBlock(nil)
            }
        }
        self.finishSendingMessage()
    }
    
    
    func loadMessages() {
        println("starting messages")
        println("new current group is")
        println(PFUser.currentUser()!["currentGroup"]!["name"])
        println(messages.count)
        var lastMessage: JSQMessage? = nil
        
        if messages.last != nil {
            println("messages is not nil, you fool! ")
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
                println("starting query")
                println(messageResults!.count)
                for message in messageResults! {
                    println("starting loop")
                    self.messageObjects.append(message)
                    let user = message["senderNew"] as! PFUser
                    println(123)
                    user.fetch()
                    println(456)
                    self.users.append(user)
                    //Need to exclude the logged in user here
                    let incoming = user
                    let incomingUsername = incoming.username! as NSString
                    
                    self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(incomingUsername.substringWithRange(NSMakeRange(0, 3)), backgroundColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), font: UIFont.systemFontOfSize(14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                    

                    
                    let chatMessage = JSQMessage(senderId: user.objectId!, senderDisplayName: user.username!, date: message.createdAt!, text: message["message"]! as! String)
                    self.messages.append(chatMessage)
                    println(4)
                }
                if results!.count > 0 {
                    self.finishReceivingMessage()
                }
            } else {
                println("error")
            }
        }
    }
    
    
    //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldReLoad == true {
            println("reloading")
            println(1)
            //We need to reset all the array variables so that loadMessages will pull an entirey different set of messages for the new currentGroup
            PFUser.currentUser()?.fetch()
            shouldReLoad = false
            self.messages = []
            self.messageObjects = []
            self.users = []
            loadMessages()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadMessages", name: "reloadMessages", object: nil)
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        //We only want the chat to get updated in real time if the user is on the chat screen
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "reloadMessages", object: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        println(2)
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
        //Need to make a custom view or somehow change title of navigation controller
        self.title = "Messages"
        self.senderId = PFUser.currentUser()!.objectId
        self.senderDisplayName = PFUser.currentUser()!.username
        //Disable the attachment button
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        /*
        var query = PFUser.query()
        query?.whereKey("username", equalTo: "andreasdjokic")
        var incoming = query?.getFirstObject() as! PFUser
        */
        
        let lightBlue = UIColor(red: 0, green: 191, blue: 255, alpha: 1)
        
        let selfUsername = PFUser.currentUser()!.username! as NSString
        //let incomingUsername = incoming.username! as NSString
        
        //selfAvatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials("Me", backgroundColor: UIColor.blackColor(), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        //incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(incomingUsername.substringWithRange(NSMakeRange(0, 2)), backgroundColor: UIColor.blackColor(), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        //0, 191, 255
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImage = bubbleFactory.outgoingMessagesBubbleImageWithColor(lightBlue)
        incomingBubbleImage = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.orangeColor())
        
        //For when the user touches an obscure area of the view
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "close")
        view.addGestureRecognizer(tap)
        
        loadMessages()
    }
    
    //For when the user touches an obscure area of the view
    func close() {
        view.endEditing(true)
    }


    
    // MARK: - DELEGATE METHODS
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        
        if message.senderId == self.senderId {
            return selfAvatar
        }
        return incomingAvatar
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        return nil
    }
    
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as? JSQMessagesCollectionViewCell
        let message = messages[indexPath.row]
        if message.senderId == self.senderId {
            cell!.textView.textColor = UIColor.blackColor()
        } else {
            cell!.textView.textColor = UIColor.blackColor()
        }
        
        cell!.textView.linkTextAttributes = [NSForegroundColorAttributeName:cell!.textView.textColor]
        return cell!
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        view.endEditing(true)
        
    }
    
    
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        println(3)
        println(messages.count)
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


//
//  ChatDetailViewController.swift
//  Chat
//
//  Created by My App Templates Team on 26/08/14.
//  Copyright (c) 2014 My App Templates. All rights reserved.
//

import UIKit

class ChatDetailViewController: UIViewController, UITextFieldDelegate {

    var userName = PFUser.currentUser().username as NSString
    var receivers = [String]()
    var group = "$$Bitches"
    
    
    var messageArray = [String]()
    var senderArray = [String]()
    
    @IBOutlet weak var composeChatView: UIView!
    @IBOutlet weak var chatTbl: UITableView!
    @IBOutlet weak var chatTxtField: UITextField!
    
    var messages : NSMutableArray!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }

    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("willShowKeyBoard:"), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("willHideKeyBoard:"), name:UIKeyboardWillHideNotification, object: nil)
        //println(self.composeChatView.frame.origin.y)
        //println(self.composeChatView.frame.size.height)
        //println(self.chatTbl.frame.origin.y)
        //println(self.chatTbl.frame.size.height)
        messages = NSMutableArray()
        chatTxtField.delegate = self
        getMessages()
        var query = PFQuery(className:"Group")
        query.whereKey("name", equalTo:group)
        query.getFirstObjectInBackgroundWithBlock {
            (object: PFObject!, error: NSError!) -> Void in
            if error == nil {
                self.receivers = object["users"] as! [String]
            } else {
                NSLog("Error: %@ %@", error, error.userInfo!)
            }
        }
        //println(self.composeChatView.frame.origin.y)
        //println(self.chatTbl.frame.origin.y)

    }


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addMessage(message: String, ofType msgType:String) {
        messages.addObject(["message":message, "type":msgType])
    }
    
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var messageDic = messages.objectAtIndex(indexPath.row) as! [String : String];
        var msg = messageDic["message"] as NSString!
        var sizeOFStr = self.getSizeOfString(msg)
        return sizeOFStr.height + 70
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        var cell : UITableViewCell!
        var messageDic = messages.objectAtIndex(indexPath.row) as! [String : String];
        var msgType = messageDic["type"] as NSString!
        var msg = messageDic["message"] as NSString!
        var sizeOFStr = self.getSizeOfString(msg)
        
        if (msgType.isEqualToString("1")){
            //Then the message is from someone other than the logged in user
            cell = chatTbl.dequeueReusableCellWithIdentifier("ChatSentCell") as! UITableViewCell
            var textLable = cell.viewWithTag(12) as! UILabel
            var nameLable = cell.viewWithTag(11) as! UILabel
            var chatImage = cell.viewWithTag(1) as! UIImageView
            var profileImage = cell.viewWithTag(2) as! UIImageView
            chatImage.frame = CGRectMake(chatImage.frame.origin.x, chatImage.frame.origin.y, ((sizeOFStr.width + 60)  > 100 ? (sizeOFStr.width + 60) : 100), sizeOFStr.height + 40)
            chatImage.image = UIImage(named: "chat_new_receive")?.stretchableImageWithLeftCapWidth(40,topCapHeight: 20);
            textLable.frame = CGRectMake(textLable.frame.origin.x, textLable.frame.origin.y, textLable.frame.size.width, sizeOFStr.height)
            profileImage.center = CGPointMake(profileImage.center.x, textLable.frame.origin.y + textLable.frame.size.height - profileImage.frame.size.height/2 + 10)
            textLable.text = msg as? String
            nameLable.text = self.senderArray[indexPath.row]
        } else {
            //The logged in user sent this message
            cell = chatTbl.dequeueReusableCellWithIdentifier("ChatReceivedCell") as! UITableViewCell
            var deliveredLabel = cell.viewWithTag(13) as! UILabel
            var textLable = cell.viewWithTag(12) as! UILabel
            var timeLabel = cell.viewWithTag(11) as! UILabel
            var chatImage = cell.viewWithTag(1) as! UIImageView
            var profileImage = cell.viewWithTag(2) as! UIImageView
            //profileImage.image = UIImage(named: "profileIcon")
            //profileImage.frame.size = CGSizeMake(34, 34)
            //profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
            var distanceFactor = (170.0 - sizeOFStr.width) < 130 ? (170.0 - sizeOFStr.width) : 130
            chatImage.frame = CGRectMake(20 + distanceFactor, chatImage.frame.origin.y, ((sizeOFStr.width + 60)  > 100 ? (sizeOFStr.width + 60) : 100), sizeOFStr.height + 40)
            chatImage.image = UIImage(named: "chat_new_send")?.stretchableImageWithLeftCapWidth(20,topCapHeight: 20);
            textLable.frame = CGRectMake(36 + distanceFactor, textLable.frame.origin.y, textLable.frame.size.width, sizeOFStr.height)
            profileImage.center = CGPointMake(profileImage.center.x, textLable.frame.origin.y + textLable.frame.size.height - profileImage.frame.size.height/2 + 10)
            timeLabel.frame = CGRectMake(36 + distanceFactor, timeLabel.frame.origin.y, timeLabel.frame.size.width, timeLabel.frame.size.height)
            deliveredLabel.frame = CGRectMake(deliveredLabel.frame.origin.x, textLable.frame.origin.y + textLable.frame.size.height + 20, deliveredLabel.frame.size.width, deliveredLabel.frame.size.height)
            textLable.text = msg as? String
            var nameLable = cell.viewWithTag(11) as! UILabel
            nameLable.text = self.senderArray[indexPath.row]
        }
        return cell
    }
    
    func getMessages() {
        
        let P1 = NSPredicate(format: "group = %@", group)
        var query = PFQuery(className: "Messages", predicate: P1)
        query.addAscendingOrder("createdAt")
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
                if error == nil {
                    for object in objects {
                        self.senderArray.append(object.objectForKey("sender") as! String)
                        self.messageArray.append(object.objectForKey("message") as! String)
                    }
                    
                    for var i = 0; i <= self.messageArray.count-1; i++ {
                        if self.senderArray[i] == self.userName {
                            self.addMessage(self.messageArray[i], ofType: "2")
                        
                        } else {
                            self.addMessage(self.messageArray[i], ofType: "1")

                        }
                    //These lines need to go here and not in view did load, because otherwise the query will evaluate
                    //these lines before it's done querying
                    self.chatTbl.reloadData()
                    var indexPath = NSIndexPath(forRow:messages.count-1, inSection: 0)
                    self.chatTbl.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                   
                }
                
            }
        }
        
    }
    
    
    
    
    func willShowKeyBoard(notification : NSNotification){
        //println("starting")
        
        var userInfo: NSDictionary!
        userInfo = notification.userInfo
        
        var duration : NSTimeInterval = 0
        var curve = userInfo.objectForKey(UIKeyboardAnimationCurveUserInfoKey) as! UInt
        duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        var keyboardF:NSValue = userInfo.objectForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        var keyboardFrame = keyboardF.CGRectValue()
        

        
        UIView.animateWithDuration(duration, delay: 0, options:nil, animations: {
            
            self.composeChatView.frame = CGRectMake(self.composeChatView.frame.origin.x, self.composeChatView.frame.origin.y - keyboardFrame.size.height+self.composeChatView.frame.size.height+3, self.composeChatView.frame.size.width, self.composeChatView.frame.size.height)
            
            self.chatTbl.frame = CGRectMake(self.chatTbl.frame.origin.x, self.chatTbl.frame.origin.y, self.chatTbl.frame.size.width, self.chatTbl.frame.size.height - keyboardFrame.size.height+49);
            

            
            }, completion: nil)
        var indexPath = NSIndexPath(forRow:messages.count-1, inSection: 0)
        chatTbl.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        //println("ComposeChatView Y Origin is \(self.composeChatView.frame.origin.y)")
        //println("ComposeChatView Height is \(self.composeChatView.frame.size.height)")
        //println("ChatTbl Y Origin is \(self.chatTbl.frame.origin.y)")
        //println("ChatTbl Heigh is \(self.chatTbl.frame.size.height)")
        //println(keyboardFrame.origin.y)
        //println(keyboardFrame.size.height)
        //println(self.chatTbl.frame.origin.y)
        //println(self.chatTbl.frame.height)
        

    }
    
    func willHideKeyBoard(notification : NSNotification){
        //println("ending")
        
        
        var userInfo: NSDictionary!
        userInfo = notification.userInfo
        
        var duration : NSTimeInterval = 0
        var curve = userInfo.objectForKey(UIKeyboardAnimationCurveUserInfoKey) as! UInt
        duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        var keyboardF:NSValue = userInfo.objectForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        var keyboardFrame = keyboardF.CGRectValue()
        
        UIView.animateWithDuration(duration, delay: 0, options:nil, animations: {
            
            self.composeChatView.frame = CGRectMake(self.composeChatView.frame.origin.x, self.composeChatView.frame.origin.y + keyboardFrame.size.height-self.composeChatView.frame.size.height-3, self.composeChatView.frame.size.width, self.composeChatView.frame.size.height)
            self.chatTbl.frame = CGRectMake(self.chatTbl.frame.origin.x, self.chatTbl.frame.origin.y, self.chatTbl.frame.size.width, self.chatTbl.frame.size.height + keyboardFrame.size.height-49);
            
 

            
            
            
           
            
            }, completion: nil)
        
        //println("ComposeChatView Y Origin is \(self.composeChatView.frame.origin.y)")
        //println("ComposeChatView Height is \(self.composeChatView.frame.size.height)")
        //println("ChatTbl Y Origin is \(self.chatTbl.frame.origin.y)")
        //println("ChatTbl Heigh is \(self.chatTbl.frame.size.height)")


    }
    
    func textFieldShouldReturn (textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func sendMessage() {
        if chatTxtField.text == "" {
            println("no text")
        }
        else {
            var message = PFObject(className: "Messages")
            message["sender"] = userName
            message["receivers"] = receivers
            message["message"] = chatTxtField.text
            message["group"] = group
            message.saveInBackgroundWithBlock {
                (success:Bool!, error:NSError!) -> Void in
                    if success == true {
                        self.addMessage(self.chatTxtField.text, ofType: "2")
                        self.senderArray.append(self.userName as! String)
                        self.chatTxtField.text = ""
                        //var  cell = self.chatTbl.dequeueReusableCellWithIdentifier("ChatReceivedCell") as! UITableViewCell
                        //var deliveredLabel = cell.viewWithTag(13) as! UILabel
                        //deliveredLabel.hidden = false
                        
                        println("Number of messags is \(self.messages.count)")
                        self.chatTbl.reloadData()
                        var indexPath = NSIndexPath(forRow:messages.count-1, inSection: 0)
                        println("The indexPath number is \(indexPath.row)")
                        println("The number of senders is \(self.senderArray.count)")
                        self.chatTbl.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                    } else {
                        println(error)
                    }
            }
            
        }
    }
    
    
    
    

    func getSizeOfString(postTitle: NSString) -> CGSize {
        // Get the height of the font
        let constraintSize = CGSizeMake(170, CGFloat.max)
        
        let attributes = [NSFontAttributeName:UIFont.systemFontOfSize(11.0)]
        let labelSize = postTitle.boundingRectWithSize(constraintSize,
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: attributes,
            context: nil)
        return labelSize.size
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
            self.view.endEditing(true)
    }
    
    
    
    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}

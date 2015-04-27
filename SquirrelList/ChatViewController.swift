//
//  ChatViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/24/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "messages" {
            let controller = segue.destinationViewController as! MessagesViewController
        }
    
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

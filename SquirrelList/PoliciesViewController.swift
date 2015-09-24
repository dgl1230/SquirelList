//
//  PoliciesViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 6/7/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//View Controller for the privacy policy and terms of service pages

import UIKit

class PoliciesViewController: UIViewController, UIScrollViewDelegate {

    //Variable for determing type of policy to show - either "Privacy Policy" or "Terms of Service"
    var policy = ""
    
    //This button is only used for when Privacy Policy/Terms of Service is being clicked on the register page, in order to close dismiss the modular segue
    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var textView: UITextView!
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if policy == "Privacy Policy" {
        let path = NSBundle.mainBundle().URLForResource("Privacy_Policy", withExtension: "rtf", subdirectory: nil, localization: nil)
        let content = try? NSAttributedString(fileURL: path!, options: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType], documentAttributes: nil)
        textView.attributedText = content
        self.title = "Privacy Policy"
    } else if policy == "Terms of Service" {
        let path = NSBundle.mainBundle().URLForResource("Terms_Of_Service", withExtension: "rtf", subdirectory: nil, localization: nil)
        let content = try? NSAttributedString(fileURL: path!, options: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType], documentAttributes: nil)
        textView.attributedText = content
        self.title = "Terms of Service"
    }
    //Set the close button icon to 'fa-times'
    closeButton?.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
    closeButton?.setTitle("\u{f00d}", forState: .Normal)

    }


}

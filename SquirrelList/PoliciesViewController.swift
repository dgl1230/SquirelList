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

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if policy == "Privacy Policy" {
        let path = NSBundle.mainBundle().URLForResource("Privacy_Policy", withExtension: "rtf", subdirectory: nil, localization: nil)
        let content = NSAttributedString(fileURL: path, options: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType], documentAttributes: nil, error: nil)
        textView.attributedText = content
        self.title = "Privacy Policy"
    } else if policy == "Terms of Service" {
        let path = NSBundle.mainBundle().URLForResource("Terms_Of_Service", withExtension: "rtf", subdirectory: nil, localization: nil)
        let content = NSAttributedString(fileURL: path, options: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType], documentAttributes: nil, error: nil)
        textView.attributedText = content
        self.title = "Terms of Service"
    }

    }


}

//
//  EditProfileViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/9/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate{

    var currentUser = PFUser.currentUser()

    var imageWasSelected = false

    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func uploadImage(sender: AnyObject) {
        var image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    
    //Should be its own extension 
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        profilePicImageView.image = image
        imageWasSelected = true
    }
    
    @IBAction func save(sender: AnyObject) {
        if firstNameTextField.text != "" {
            currentUser["first_name"] = firstNameTextField.text
        }
        if lastNameTextField.text != "" {
            currentUser["last_name"] = lastNameTextField.text
        }
        if imageWasSelected {
            let imageData = UIImagePNGRepresentation(profilePicImageView.image)
            let imageFile = PFFile(name: currentUser.username + "png", data: imageData)
            currentUser["profile_pic"] =  imageFile
        }
        currentUser.save()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Should be its own extension
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var oldName: NSString = ""
            var newName: NSString = ""
            if textField.tag == 1 {
                //they are typing in the first name field
                println("going here")
                oldName = firstNameTextField.text
                newName = oldName.stringByReplacingCharactersInRange(range, withString: string)
            } else {
                //they are typing in the last name field
                oldName = lastNameTextField.text
                newName = oldName.stringByReplacingCharactersInRange(range, withString: string)
            }
        
            if newName.length > 0 {
                saveButton.enabled = true
            } else {
                saveButton.enabled = false
            }
            return true 
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        if currentUser["first_name"] != nil {
            firstNameTextField.text = currentUser["first_name"] as String
        }
        if currentUser["last_name"] != nil {
            lastNameTextField.text = currentUser["last_name"] as String
        }
        if currentUser["profile_pic"] != nil {
            let userImageFile = currentUser["profile_pic"] as PFFile
            userImageFile.getDataInBackgroundWithBlock {
                (imageData: NSData!, error: NSError!) -> Void in
                    if error == nil {
                        self.profilePicImageView.image = UIImage(data:imageData)
                    }
            }
        }
        
        
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

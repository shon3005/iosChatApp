//
//  LoginController+handlers.swift
//  gameofchats
//
//  Created by Shaun Chua on 3/5/17.
//  Copyright © 2017 Shaun Chua. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleRegister() {
        // register to firebase
        // input all three fields if not, error
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        // creates user in firebase
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
            
            if error != nil {
                print(error)
                return
            }
            
            // create uid entity
            guard let uid = user?.uid else {
                return
            }
            
            // successfully authenticated user
            let imageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            // compress size of image file to 10% of size
            // this optional is to unwrap an actual image only, won't unwrap when there is no image attached to profile
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
            //if let uploadData = UIImageJPEGRepresentation(self.profileImageView.image!, 0.1) {
            //if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
                storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil  {
                        print(error)
                        return
                    }
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                        // the values of name and email are parameters within uid class
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                        self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String : AnyObject])
                    }
                    print(metadata)
                })
            }
        })
    }
    
    
    // the actual function to store values into uid class on database
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference()
        // specify uid as a subclass of users as a subclass of whole database
        let usersReference = ref.child("users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err)
                return
            }
            print("Saved user successfully into Firebase db")
            
            // self.messagesController?.fetchUserAndSetupNavBarTitle()
            // use this statement instead of above statement to fetch the username for nav bar title
            // self.messagesController?.navigationItem.title = values["name"] as? String
            let user = User()
            // this setter potentially crashes if keys don't match
            user.setValuesForKeys(values)
            
            // don't need to fetch user, since you're registering
            // makes sure that the nav bar title is set
            self.messagesController?.setupNavBarWithUser(user: user)
            
            // dismiss the login view upon clicking register
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    // presents the picture picker view
    func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // to edit size of the image
        var selectedImageFromPicker: UIImage?
        if let editedImage =
            info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage =
            info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        // optional to unwrap the selectedImage to display on the imageView
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        // dismiss the view controller
        dismiss(animated: true, completion: nil)
    }
    
    // function to cancel the profile picture selection
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
}

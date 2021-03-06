//
//  ChatLogController.swift
//  gameofchats
//
//  Created by Shaun Chua on 3/7/17.
//  Copyright © 2017 Shaun Chua. All rights reserved.
//

import UIKit
import Firebase

// opens the chat log
class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
    // set title of navigation bar to user title
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    // ref for user messages
    func observeMessages() {
        // current logged in user
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        // observe all the messages
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid)
        // child added for all the children under this node
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                print(snapshot)
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                let message = Message()
                // potential of crashing if keys don't match
                message.setValuesForKeys(dictionary)
                
                // check if chatPartnerID is user?.id only see chat partner's messages
                if message.chatPartnerId() == self.user?.id {
                    self.messages.append(message)
                    // because we are in a background thread, to get back on to the main thread
                    // changing ui components
                    DispatchQueue.main.async(execute: {
                        // refresh the collectionView
                        self.collectionView?.reloadData()
                    })
                }
                
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        // register cell id to cell
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        setupInputComponents()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // put the text on the cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        
        return cell
    }
    
    // cells will expand to cover width of controller
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
    
    func setupInputComponents() {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        // constraint anchors
        // x,y,width,height
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        // x,y,w,h
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // this chunk of code was moved to the top
//        let inputTextField = UITextField()
//        inputTextField.placeholder = "Enter Message..."
//        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(inputTextField)
        
        // x,y,w,h
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        // x,y,w,h
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
    }
    
    // sends the messages to database
    func handleSend() {
        let ref = FIRDatabase.database().reference().child("messages")
        // feature to allow for many messages to send to database without updating the same message
        // not good to save name to database with message, use id instead
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timeStamp = Int(NSDate().timeIntervalSince1970)
        let childRef = ref.childByAutoId()
        let values = ["text": inputTextField.text!, "toId": toId, "fromId": fromId, "timeStamp": timeStamp] as [String : Any]
        // childRef.updateChildValues(values)
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error)
                return
            }
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId:1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId)
            recipientUserMessagesRef.updateChildValues([messageId:1])
        }
    }
    
    // allow for the enter button to send message as well
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        handleSend()
        return true
    }
}

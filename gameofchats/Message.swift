//
//  Message.swift
//  gameofchats
//
//  Created by Shaun Chua on 3/9/17.
//  Copyright © 2017 Shaun Chua. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var fromId: String?
    var text: String?
    var timeStamp: NSNumber?
    var toId: String?
    
    func chatPartnerId() -> String? {
    
        // determine id of the last person who sent chat message
        if fromId == FIRAuth.auth()?.currentUser?.uid {
            return toId
        } else {
            return fromId
        }
    }
}

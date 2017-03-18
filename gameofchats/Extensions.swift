//
//  Extensions.swift
//  gameofchats
//
//  Created by Shaun Chua on 3/6/17.
//  Copyright © 2017 Shaun Chua. All rights reserved.
//

// this helper helps to reduce download cost, when image is loaded, it doesnt download the image again when user stays on the view controller

import UIKit

// memory bank for all our images
let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        // check cache for UIImage first and load if it exists
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        // otherwise fire off a new download
        let url = URL(string: urlString)
        
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            // download hit an error so lets return out
            if error != nil {
                print(error!)
                return
            }
            
            // threading technique
            DispatchQueue.main.async(execute: {
                // do this unwrapping safely
                if let downloadedImage = UIImage(data: data!) {
                    // add to the cache
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    // set image to downloaded image
                    self.image = downloadedImage
                }
            })
            
        }).resume()
    }
}

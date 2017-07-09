//
//  Photos.swift
//  FlickrDemo
//
//  Created by Egidijus Ambrazas on 08/07/2017.
//  Copyright © 2017 Egidijus Ambrazas. All rights reserved.
//

import UIKit

class Photo {
    let imageUrl: String
    var title: String
    
    var imageIsLoaded: Bool?
    var image: UIImage?
    
    
    // 
    init(fromDictionary: [String: AnyObject]) {
        
        imageUrl = "https://farm\(fromDictionary["farm"]!).staticflickr.com/\(fromDictionary["server"]!)/\(fromDictionary["id"]!)_\(fromDictionary["secret"]!).jpg"
        
        title = "\(fromDictionary["title"]!)"
        if title.isEmpty {
            title = "No title"
        }

        imageIsLoaded = nil
        image = nil
    }
}

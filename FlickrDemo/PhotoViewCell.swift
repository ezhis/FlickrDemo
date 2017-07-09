//
//  PhotoViewCell.swift
//  FlickrDemo
//
//  Created by Egidijus Ambrazas on 08/07/2017.
//  Copyright © 2017 Egidijus Ambrazas. All rights reserved.
//

import UIKit

class PhotoViewCell: UICollectionViewCell {
    weak var collectionController:ViewController?
    
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func animate(){
        collectionController?.animateImageView(image: photoView)
    }
    
    // set view to its default look
    func reset(){
        photoView.image = nil
        titleLabel.text = "Loading..."
        
        cellView.layer.cornerRadius = 5.0
        cellView.layer.borderColor = UIColor.lightGray.cgColor
        cellView.layer.borderWidth = 0.5
        cellView.clipsToBounds = true
       
    }
    
    var photo: Photo? {
        didSet{
           
            titleLabel.text = photo?.title
            
            // if photo is already loaded, do not load it again.
            if (photo?.imageIsLoaded ?? false){
                self.photoView.image = photo?.image
                return
            }
            
            guard let imageUrl = photo?.imageUrl else {return}
            guard let url = URL(string: imageUrl) else {return}
            
            //Download image in background thread
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                //
                if let err = error {
                    print("Failed to load image", err)
                }

                guard let imageData = data else {return}
                if let image = UIImage(data: imageData){
                    //Updating UI.
                    DispatchQueue.main.async {
                        self.photoView.image = image
                        self.photo?.image = image
                        self.photo?.imageIsLoaded = true
                    }
                }
                }.resume() // Start task
            
            // Gesture tap to show image in black background
            photoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(animate)))
            photoView.isUserInteractionEnabled = true
        }
    }
}

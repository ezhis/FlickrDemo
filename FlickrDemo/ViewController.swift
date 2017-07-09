//
//  ViewController.swift
//  FlickrDemo
//
//  Created by Egidijus Ambrazas on 08/07/2017.
//  Copyright © 2017 Egidijus Ambrazas. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    var photos = [Photo]()
    var gettingDataFromServer = false
    let zoomImage = UIImageView()
    var imageView: UIImageView?
    var blackView = UIView()
    
    var titleIsVisible = false
    var dataDictionary:NSDictionary?
    var sortDescending = true;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Loading Data.plist file
        if let dataUrl = Bundle.main.path(forResource: "Data", ofType: "plist"){
            dataDictionary = NSDictionary(contentsOfFile: dataUrl)
        }
                
        
        //This removes border on navigationBar
        let navigationBar = navigationController!.navigationBar
        navigationBar.setBackgroundImage(#imageLiteral(resourceName: "white"),for: .default)
        navigationBar.isTranslucent = false
        navigationBar.shadowImage = UIImage()

        //sets alpha of navigation tiitle to zero
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.black.withAlphaComponent(0)]
        
        //loading images from flickr server
        getImageFromFlickr()
    }
    
    // when scrollview moves up by 88 pixels unhiding navigation title
    // simple atempt to implement something similar to new ios 11 apps (appstore, music)
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !titleIsVisible && scrollView.contentOffset.y > 88 {
            titleIsVisible = true
           
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.black.withAlphaComponent(1)]
        }
        
        if titleIsVisible && scrollView.contentOffset.y < 88 {
            titleIsVisible = false
            
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.black.withAlphaComponent(0.0)]
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // sinse collection view uses two types of cellView ir has to retrun different heigh
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       
        if indexPath.item == 0 { // header cell
            return CGSize(width: view.frame.width - 20, height: 110)
        } else { // photo cell
            return CGSize(width: view.frame.width - 20, height: 330)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // collectionview allways try to show one additional cell. And when that cell will be initialized new photos will be loaded
        return photos.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 { // Header cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "headerCell", for: indexPath) as! HeaderViewCell
            cell.titleLabel.text = dataDictionary?["headerTitle"] as? String
            return cell
            
        } else { // Photo Cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! PhotoViewCell
            cell.collectionController = self
            cell.reset()
        
            
            if indexPath.item > (photos.count - 1) { // for last cell we still have data, so need todowload
                if(!gettingDataFromServer){ // checking gettingDataFromServer prevents to start new dta task, while another is still going
                    getImageFromFlickr()
                }
            } else {
                cell.photo = photos[indexPath.item]
            }

            return cell
        }
        
    }
    
    // Handling screen risize/rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //resizing collectioView
        collectionViewLayout.invalidateLayout()
        
        guard let keyWindow = UIApplication.shared.keyWindow  else {
            return
        }
        
        // resizing blackView and zoomImage Views
        if blackView.superview != nil {
            var destinationRect = keyWindow.bounds
            
            // viewWillTransition method gives only current View destination size, but we need destination size of KeyWindow. comparing "size" aspect ratio twith KeyWindow.bounds let see if window rotates.
            if (size.width > size.height && keyWindow.bounds.width < keyWindow.bounds.height ) || (size.width < size.height && keyWindow.bounds.width > keyWindow.bounds.height ) {
                destinationRect = CGRect(x: 0, y: 0, width: keyWindow.bounds.height, height: keyWindow.bounds.width)
            }
            
            // size of blackView should be bigger than screen size, this lets to cover whole sreen during rotation
            blackView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: size.width * 2, height: size.height * 2))
            
            let imageSize = imageView?.image?.size
            
            // callculating image size to fit in screen.
            let imageAspectRatio = (imageSize?.width)! / (imageSize?.height)!
            let screenAspectRatio = destinationRect.width / destinationRect.height
            
            
            var destinationWidth: CGFloat = 0
            var destinationHeight: CGFloat = 0
            var scale: CGFloat = 1
            
            if(imageAspectRatio > screenAspectRatio) {
                destinationWidth = destinationRect.width
                scale = (imageSize?.width)! / destinationWidth
                destinationHeight =  (imageSize?.height)! / scale
            } else {
                destinationHeight = destinationRect.height
                scale = (imageSize?.height)! / destinationHeight
                destinationWidth = (imageSize?.width)! / scale
            }
            
            let destinationFrame = CGRect(x: (destinationRect.width - destinationWidth) / 2, y: destinationRect.midY - destinationHeight / 2 , width: destinationWidth, height: destinationHeight)
            
            print(destinationFrame)
            print(destinationRect.midX )
            
            self.zoomImage.frame = destinationFrame
            
        }
    }
    @IBAction func sortPhotos(_ sender: Any) {
        if(sortDescending) {
            photos.sort(by: { $0.title > $1.title })
        } else {
             photos.sort(by: { $0.title < $1.title })
        }
         print("Sort descending \(sortDescending)")
        sortDescending = !sortDescending
        collectionView?.reloadData()
        
        sortButton.image = sortDescending ? #imageLiteral(resourceName: "icons8-alphabetical_sorting_2_filled") : #imageLiteral(resourceName: "icons8-alphabetical_sorting_filled")
       
    }
    
    private func getImageFromFlickr() {
        gettingDataFromServer = true;
        
        // setting Urlreguest object
        let url = URL(string: dataDictionary?["recentPhotodUrl"] as! String )!
        let request = URLRequest(url: url)
        
        // creating network request task
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and set gettingDataFromServer to true, this tels to start new dowload task
            func displayError(_ error: String) {
                print(error)
                self.gettingDataFromServer = false;
            }
            
            // return if error occur in request
            guard (error == nil) else {
                displayError("There was an error with your request: \(error!)")
                return
            }
            
           // return if response code other than 2XX.
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            // return if no data was returned
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // JSON serialization, if something wrong - return
            let parsedResult: [String:AnyObject]! // parsed JSON.
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // return if Flickr api return error. "stat" key should be equal to "ok"
            // doing query, api do not return "stat" key
            /*guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }*/
            
            // get "photo" Array from parsedResult
            guard let query = parsedResult["query"] as? [String:AnyObject], let results = query["results"] as? [String:AnyObject], let photoArray = results["photo"] as? [[String:AnyObject]] else {
                displayError("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                return
            }
            
            // collect all photos from  photoArray and append 'photos' array
            for photoDada in photoArray{
                let photo = Photo(fromDictionary: photoDada)
                self.photos.append(photo)
            }
            // since loading and parsing is done in background thread we need to call UI thread to make ui updates
            DispatchQueue.main.sync {
                // reload collectionView
               self.collectionView?.reloadData()
            }
            
            // loading and parsing is done
            self.gettingDataFromServer = false
            

        }
        
        // start the task!
        task.resume()
    }
    
    // cretes new image on top of all view and moves that image to center
    func animateImageView(image:UIImageView){
        
        // to hide navigation bar blackView and zoomImage should be added to parent view. taht parent view is keyWindow
        guard let keyWindow = UIApplication.shared.keyWindow  else {
            return
        }
        
        self.imageView = image
        //zoomImage should be exactly in same position like original image. since it is in different view that postion should be converted parent view cordinetes system.
        let startPositionFrame =  keyWindow.convert(image.frame, from: image.superview)
        
        blackView.frame = keyWindow.frame // fill the screen with black color
        blackView.backgroundColor = .black
        blackView.alpha = 0 //at firts alpha should be 0, later it will animated to 1
        image.alpha = 0
        
        zoomImage.image = image.image
        zoomImage.contentMode = .scaleAspectFill
        zoomImage.clipsToBounds = true
        zoomImage.frame = startPositionFrame
        zoomImage.backgroundColor = .red
        
        keyWindow.addSubview(blackView)
        keyWindow.addSubview(zoomImage)
        
        
        // make backView and zoomImage visible. animation allso makes fhoto to fit screen, but keeps aspect ration corect.
        UIView.animate(withDuration: 0.75, animations: {
            let size = image.image?.size
            
            let imageAspectRatio = (size?.width)! / (size?.height)!
            let screenAspectRatio = keyWindow.bounds.width / keyWindow.bounds.height
            
            var destinationWidth: CGFloat = 0
            var destinationHeight: CGFloat = 0
            var scale: CGFloat = 1
            
            if(imageAspectRatio > screenAspectRatio) {
                destinationWidth = keyWindow.bounds.width
                scale = (size?.width)! / destinationWidth
                destinationHeight =  (size?.height)! / scale
            } else {
                destinationHeight = keyWindow.bounds.height
                scale = (size?.height)! / destinationHeight
                destinationWidth = (size?.width)! / scale
            }
            
            let destinationFrame = CGRect(x: keyWindow.bounds.midX - destinationWidth / 2, y: keyWindow.bounds.midY - destinationHeight / 2 , width: destinationWidth, height: destinationHeight)
            self.zoomImage.frame = destinationFrame
            
            
            self.blackView.alpha = 1
        })
        
        // Adding tap gesture to image, to let close zoomed image
        zoomImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fadeoutImageView)))
        zoomImage.isUserInteractionEnabled = true
    }
    
    // fading out zoomImage and blackView, and move zoomImage to its original position. this makes it look that there is only one image
    func fadeoutImageView(){
        
        guard let keyWindow = UIApplication.shared.keyWindow  else {
            return
        }
        
        let endPositionFrame =  keyWindow.convert((imageView?.frame)!, from: imageView?.superview)
        UIView.animate(withDuration: 0.75, animations: {
            self.zoomImage.frame = endPositionFrame
            self.blackView.alpha = 0
        }, completion: {(finished: Bool) in
            self.imageView?.alpha = 1
            self.zoomImage.removeFromSuperview()
            self.blackView.removeFromSuperview()
        })
        
        
    }

    
    
}


/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GalleryVCDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filterTableView: UICollectionView!
    @IBOutlet weak var filterCollectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var uploadImageButton: UIButton!
    @IBOutlet weak var applyFiltersButton: UIButton!
    
    var currentPhoto: UIImage? {
        didSet {
            filterTableView.reloadData()
            imageView.image = currentPhoto
        }
    }
    
    let defaultImagePlaceholder = UIImage(named: "flowers")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tabBarController = self.tabBarController, viewControllers = tabBarController.viewControllers {
            if let galleryViewController = viewControllers[1] as? GalleryViewController {
                galleryViewController.delegate = self
                self.filterTableView.reloadData()
            }
        }
        
        // Tap Gesture Recognizer
        imageView.userInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: "tapView:")
        imageView.gestureRecognizers = [tapGesture]
    }
    
    func tapView(gesture: UITapGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            self.presentActionSheet()
        } else {
            self.presentImagePickerFor(.PhotoLibrary)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.imageView.image = self.defaultImagePlaceholder
        self.filterTableView.reloadData()
    }
    
    func galleryViewControllerDidFinish(image: UIImage) {
        
        // Set this View Controllers image to image
        self.currentPhoto = image
        self.imageView.image = self.currentPhoto
        // Get tabBar controller to change index
        self.tabBarController?.selectedIndex = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UIAlert
    
    func presentActionSheet() {
        
        let alertController = UIAlertController(title: "", message: "Please choose your source.", preferredStyle: .ActionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.presentImagePickerFor(.Camera)
        }
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .Default) { (action) -> Void in
            self.presentImagePickerFor(.PhotoLibrary)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cameraAction)
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func presentAlertView() {
        
        let alertController = UIAlertController(title: "", message: "Image successfully uploaded.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func noImageSelectedAlert() {
        
        let noImageAlertController = UIAlertController(title: "", message: "You have to select an image before uploading", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        noImageAlertController.addAction(okAction)
        self.presentViewController(noImageAlertController, animated: true, completion: nil)
    }
    
    // MARK: @IBActions
    
    @IBAction func AddImagePressed(sender: UITapGestureRecognizer) {
        print("Image Tapped")
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            self.presentActionSheet()
        } else {
            self.presentImagePickerFor(.PhotoLibrary)
        }
    }
    
    @IBAction func filtersButtonPressed(sender: UIButton) {
        self.filterCollectionViewTopConstraint.constant = 2
        
        UIView.animateWithDuration(1.0) { () -> Void in
            self.view.layoutIfNeeded()
            self.applyFiltersButton.hidden = true
            self.uploadImageButton.hidden = true
        }
    }
    
    @IBAction func uploadImageButtonPressed(sender: UIButton) {
        
        sender.enabled = false
        if let image = self.imageView.image {
            API.uploadImage(image) { (success) -> () in
                if success {
                    sender.enabled = true
                    self.presentAlertView()
                }
            }
        } else {
            noImageSelectedAlert()
            sender.enabled = true
        }
        
    }
    
    // MARK: UIImagePickerController Delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        currentPhoto = image
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func presentImagePickerFor(sourceType: UIImagePickerControllerSourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UICollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CustomCollectionViewCell.identifier(), forIndexPath: indexPath) as! CustomCollectionViewCell
        
        cell.filteredThumbnalImageView.image = nil
        
        if let currentPhoto = currentPhoto {
            setupFilteredCell(indexPath.row, image: currentPhoto, callback: { (filteredImage) -> () in
                
                cell.filteredThumbnalImageView.image = filteredImage
                cell.filteredFullSizeImage = filteredImage
                
            })
        }
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        
        let size = (screenSize.width / 3) - 7
        imageView.image = currentPhoto
        
        return CGSizeMake(size, size)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = filterTableView.cellForItemAtIndexPath(indexPath) as! CustomCollectionViewCell
        
        currentPhoto = cell.filteredFullSizeImage
        
        self.filterCollectionViewTopConstraint.constant = 200
        UIView.animateWithDuration(1.0) { () -> Void in
            self.view.layoutIfNeeded()
            
            self.applyFiltersButton.hidden = false
            self.uploadImageButton.hidden = false
            
        }
    }
    
    //MARK: Filters
    
    func setupFilteredCell(indexPath: Int, image: UIImage, callback:(UIImage?) -> ()) {
        switch indexPath {
        case 0:
            FilterService.applyBWEfect(image, completion: { (filteredImage, name) -> Void in
                callback(filteredImage)
            })
            
        case 1:
            FilterService.applyChromeEffect(image, completion: { (filteredImage, name) -> Void in
                callback(filteredImage)
                
            })
        case 2:
            FilterService.applyVintageEffect(image, completion: { (filteredImage, name) -> Void in
                callback(filteredImage)
            })
            
        default: print("Filter outbounds")
        }
    }
}

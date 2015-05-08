//
//  SummaryViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-07.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVKit
import AVFoundation
import CoreLocation

class JobsListItemImagesViewCell : UICollectionViewCell {
    @IBOutlet var Picture : UIImageView!
    func loadItem(#image: Url) {
        if (image.type == "image"){
            Picture.image = UIImage(data: image.urldata);
        }else{
            Picture.image = UIImage(named : "video.png")
        }
        Picture.frame = CGRectMake(15,10,80,80);
    }
}

class JobsListItemViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet var request_message: UITextView!
    @IBOutlet var uploaded_images: UICollectionView!
    @IBOutlet var thingicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var guyicon: UIImageView!
    var IndexPath : NSIndexPath = NSIndexPath()
    let picker = UIImagePickerController()
    var JobID : String = ""
    
    func go_to_gallery(button:UIButton){
        self.picker.allowsEditing = false;
        self.picker.sourceType = .PhotoLibrary
        println("Go To Gallery")
        dismissViewControllerAnimated(true, completion: nil)
        presentViewController(self.picker, animated: true, completion: nil)//4
    }

    func go_to_photo(button:UIButton){
        println("Go To Photo")
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera
            var mediaTypes: Array<AnyObject> = [kUTTypeImage]
            self.picker.mediaTypes = mediaTypes
            dismissViewControllerAnimated(true, completion: nil)
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else{
            NSLog("No Camera.")
        }
    }
    
    func go_to_video(button:UIButton){
        println("Go To Video")
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera
            var mediaTypes: Array<AnyObject> = [kUTTypeMovie]
            self.picker.mediaTypes = mediaTypes
            dismissViewControllerAnimated(true, completion: nil)
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else{
            NSLog("No Camera.")
        }
    }
    
    @IBAction func take_picture(){
        var gallery = UIButton()
        gallery.setTitle("Photos", forState: .Normal)
        gallery.setImage(UIImage(named: "gallery.png"), forState: .Normal)
        gallery.frame = CGRectMake(20, 80, 50, 50)
        gallery.addTarget(self, action: "go_to_gallery:", forControlEvents: .TouchUpInside)
        
        var gallery_label = UILabel()
        gallery_label.text = "Photos"
        gallery_label.frame = CGRectMake(20, 35, 120, 50)
        
        var photo_label = UILabel()
        photo_label.text = "Camera"
        photo_label.frame = CGRectMake(110, 35, 120, 50)
        
        var photo = UIButton()
        photo.setImage(UIImage(named: "photo.png"), forState: .Normal)
        photo.frame = CGRectMake(115, 80, 50, 50)
        photo.addTarget(self, action: "go_to_photo:", forControlEvents: .TouchUpInside)
        
        var video_label = UILabel()
        video_label.text = "Video"
        video_label.frame = CGRectMake(205, 35, 120, 50)
        
        var video = UIButton()
        video.setImage(UIImage(named: "video.png"), forState: .Normal)
        video.frame = CGRectMake(203, 80, 50, 50)
        video.addTarget(self, action: "go_to_video:", forControlEvents: .TouchUpInside)
        
        let alertController = UIAlertController(title: "Upload Picture?" as String!, message: "\n\n\n\n\n",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "UPLOAD", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            self.show_review();
        }))
        alertController.addAction(UIAlertAction(title: "NO", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            self.show_review();
        }))
        alertController.view.addSubview(gallery)
        alertController.view.addSubview(photo)
        alertController.view.addSubview(video)
        alertController.view.addSubview(gallery_label)
        alertController.view.addSubview(photo_label)
        alertController.view.addSubview(video_label)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showguyicon(){
        self.thingicon.hidden = true;
        self.placeicon.hidden = true;
        self.guyicon.hidden = false;
    }
    
    func showthingicon(){
        self.thingicon.hidden = false;
        self.placeicon.hidden = true;
        self.guyicon.hidden = true;
    }
    
    func showplaceicon(){
        self.thingicon.hidden = true;
        self.placeicon.hidden = false;
        self.guyicon.hidden = true;
    }
    
    override func viewDidAppear(animated: Bool) {
        if (did_submit_photo == "true"){
            if let request = jobs_list[self.IndexPath.row] as? Jobs {
                jobs_list.removeObjectAtIndex(self.IndexPath.row)
                NSNotificationCenter.defaultCenter().postNotificationName("RemoveLocation", object: self, userInfo: request.request_dict)
            }
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func OnPhotoRequest(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var index = data["index"] as! Int
        let alertController = UIAlertController(title: "You Just Received A Photo Request!" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "View it", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("DriverSummary") as! DriverSummaryViewController
            vc.request_index = index
            self.presentViewController(vc, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Decline", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            var request = ((dispatch.jobs_buff[index]) as! Jobs).request_dict
            var driver_id = request["driver_id"]!
            var jobID = request["jobID"]!
            var requester_id = request["requester_id"]!
            var message = "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(jobID)"
            dispatch_socket.emit("declinerequest", message)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnRequestPicmiDriverFailure(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var jobID : String = data["jobID"] as! String
        println(data)
        
        if (self.JobID == jobID){
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnJobCancelled(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var jobID : String = data["jobID"] as! String
        println(data)
        
        if (self.JobID == jobID){
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        let alertController = UIAlertController(title: "Job Cancelled by user" as String!, message: "This job will be removed from your list",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil ))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnPhotoResponse(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var index = data["index"] as! Int
        let alertController = UIAlertController(title: "You have just received a response" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "View it", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MediaReview") as! MediaReviewViewController
            vc.response_index = index
            self.presentViewController(vc, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func ReceivedMessage(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        println(data)
        var index = (data["index"] as! String).toInt()
        var type = data["type"] as! String
        var username = data["username"] as! String
        var message = data["message"] as! String
        if (type == "job"){
            if((jobs_list[index!] as! Jobs).isNotified == false && self.presentedViewController == nil){
                (jobs_list[index!] as! Jobs).isNotified = true
                let alertController = UIAlertController(title: username, message: message,   preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Reply", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
                    let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MessagingController") as! MessagingViewController
                    vc.type = "job"
                    vc.IndexPath = NSIndexPath(forRow: index!, inSection: 0)
                    self.presentViewController(vc, animated: true, completion: nil)
                }))
                alertController.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }else if(type == "request"){
            if((requests_list[index!] as! Requests).isNotified == false && self.presentedViewController == nil){
                println(self.presentedViewController)
                (requests_list[index!] as! Requests).isNotified = true
                let alertController = UIAlertController(title: username, message: message,   preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Reply", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
                    let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MessagingController") as! MessagingViewController
                    vc.type = "request"
                    vc.IndexPath = NSIndexPath(forRow: index!, inSection: 0)
                    self.presentViewController(vc, animated: true, completion: nil)
                }))
                alertController.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }

    func OnTransactionEnded(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        let alertController = UIAlertController(title: "Transaction Ended" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        if let request = jobs_list[self.IndexPath.row] as? Jobs {
            if(request.request_dict["message"] != nil){
                self.request_message.text = (request.request_dict["message"])!
            }else{
                self.request_message.text = ""
            }

            switch (request.request_dict["objecttype"]!){
            case("place"):
                self.showplaceicon()
            case("thing"):
                self.showthingicon()
            default:
                self.showguyicon()
            }
            self.JobID = request.request_dict["jobID"]! as String
        }
        self.picker.delegate = self
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func declinerequest(){
        if let request = jobs_list[IndexPath.row] as? Jobs {
            var driver_id = request.request_dict["driver_id"]!
            var jobID = request.request_dict["jobID"]!
            var requester_id = request.request_dict["requester_id"]!
            var message = "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(jobID)"
            dispatch_socket.emit("declinerequest", message)
            jobs_list.removeObjectAtIndex(IndexPath.row)
            NSNotificationCenter.defaultCenter().postNotificationName("RemoveLocation", object: self, userInfo: request.request_dict)
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func showMap(){
         if let request = jobs_list[IndexPath.row] as? Jobs {
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
            vc.longitude = CLLocationDegrees((request.request_dict["longitude"] as NSString!).doubleValue)
            vc.latitude = CLLocationDegrees((request.request_dict["latitude"] as NSString!).doubleValue)
            vc.location_name = request.request_dict["location_name"] as String!
            vc.type = request.request_dict["objecttype"] as String!
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count : Int = 0
        if let request = jobs_list[self.IndexPath.row] as? Jobs {
            count = request.requests_pics_urls.count
        }
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("JobsListItemImageCell",forIndexPath: indexPath)as! JobsListItemImagesViewCell
        var tempimage : Url = Url()
        if let request = jobs_list[self.IndexPath.row] as? Jobs {
            tempimage = request.requests_pics_urls[indexPath.row] as! Url
        }
        cell.loadItem(image: tempimage)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let request = jobs_list[self.IndexPath.row] as? Jobs {
            if((request.requests_pics_urls[indexPath.row] as? Url)!.type == "video"){
                self.performSegueWithIdentifier("JobItemtoAVPlayerSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
            }else if((request.requests_pics_urls[indexPath.row] as? Url)!.type == "image"){
                self.performSegueWithIdentifier("JobItemtoEnlargedPictureSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
            }
        }
    }
    
    func show_review(){
        self.performSegueWithIdentifier("JobItemtoReviewPhotosSegue", sender: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        println(info)
        var mediaType : String = info[UIImagePickerControllerMediaType] as! String
        if (mediaType == "public.movie"){
            let tempImage = info[UIImagePickerControllerMediaURL] as! NSURL!
            println(tempImage.path!)
            var data = NSData(contentsOfFile: tempImage.path!)!
            var media = Media(temptype: "video", tempdata: data, tempurl: tempImage)
            
            dispatch.responses_media_list.addObject(media)
            
            dismissViewControllerAnimated(true, completion: nil);
            self.take_picture()
            //self.performSegueWithIdentifier("ShowVideoSegue", sender: self)
        }else{
            var media = Media(temptype: "image", tempdata: info[UIImagePickerControllerOriginalImage] as! UIImage)
            dispatch.responses_media_list.addObject(media)
            dismissViewControllerAnimated(true, completion: nil);
            self.take_picture()
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        println("did finish picking")
        var media = Media(temptype: "image", tempdata: image)
        dispatch.responses_media_list.addObject(media)
        dismissViewControllerAnimated(true, completion: nil);
        self.take_picture();
        return
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        println("Upload Pictures!")
        dismissViewControllerAnimated(true, completion: nil);
        self.take_picture();
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if let request = jobs_list[self.IndexPath.row] as? Jobs {
            if (segue.identifier == "JobItemtoAVPlayerSegue"){
                let index = uploaded_images.indexPathForCell(sender as! JobsListItemImagesViewCell)!
                let destination = (segue.destinationViewController as! AVPlayerViewController)
                let url = NSURL(string:
                    "https://s3-us-west-1.amazonaws.com/picmi-photo" + (request.requests_pics_urls[index.row] as? Url)!.urlpath)
                destination.player = AVPlayer(URL: url)
            }else if(segue.identifier == "JobItemtoEnlargedPictureSegue"){
                let index = uploaded_images.indexPathForCell(sender as! JobsListItemImagesViewCell)!
                var media = Media(temptype: "image", tempdata: UIImage(data: (request.requests_pics_urls[index.row] as? Url)!.urldata)!)
                (segue.destinationViewController as! EnlargedPictureViewController).Picture = media
            }
        }
        
        if(segue.identifier == "FromJobItemToMessageSegue"){
            (segue.destinationViewController as! MessagingViewController).type = "job"
            (segue.destinationViewController as! MessagingViewController).IndexPath = self.IndexPath
        }
        
        if (segue.identifier == "JobItemtoReviewPhotosSegue"){
            (segue.destinationViewController as! SubmissionReviewViewController).IndexPath = self.IndexPath
        }
    }
}

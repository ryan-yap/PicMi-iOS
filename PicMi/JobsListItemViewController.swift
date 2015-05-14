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
    
    @IBOutlet var uploadimagecollectionview: UICollectionView!
    
    @IBOutlet var uploadimageview: UIView!
    @IBOutlet var uploadimagewindow: UIView!
    @IBOutlet var request_message: UITextView!
    @IBOutlet var uploaded_images: UICollectionView!
    @IBOutlet var thingicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var guyicon: UIImageView!
    var IndexPath : NSIndexPath = NSIndexPath()
    let picker = UIImagePickerController()
    var JobID : String = ""
    var isDoneSelectingMedia : Bool = false
    
    @IBAction func go_to_gallery(){
        self.picker.allowsEditing = false;
        self.picker.sourceType = .PhotoLibrary
        println("Go To Gallery")
        //dismissViewControllerAnimated(true, completion: nil)
        presentViewController(self.picker, animated: true, completion: nil)//4
    }
    
    @IBAction func go_to_photo(){
        println("Go To Photo")
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera
            var mediaTypes: Array<AnyObject> = [kUTTypeImage]
            self.picker.mediaTypes = mediaTypes
            //dismissViewControllerAnimated(true, completion: nil)
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else{
            NSLog("No Camera.")
        }
    }
    
    @IBAction func go_to_video(){
        println("Go To Video")
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera
            var mediaTypes: Array<AnyObject> = [kUTTypeMovie]
            self.picker.mediaTypes = mediaTypes
            //dismissViewControllerAnimated(true, completion: nil)
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else{
            NSLog("No Camera.")
        }
    }
    
    
    @IBAction func take_picture(){
        self.uploadimageview.hidden = false
        self.uploadimagewindow.hidden = false
        UIView.animateWithDuration(0.7, animations: {
            self.uploadimagewindow.center.y = 88 + self.uploadimagewindow.frame.height/2
        })
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
        
        println(self.isDoneSelectingMedia)
        
        if (self.isDoneSelectingMedia == false){
            self.uploadimageview.hidden = true
            self.uploadimagewindow.center.y = -400
            println("isDoneSelecting Media")
        }
        
        self.isDoneSelectingMedia = false
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
        super.viewDidLoad()
        self.uploadimagewindow.center.y = -400
        self.uploadimagewindow.hidden = true
        self.uploadimageview.hidden = true
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
    
    @IBAction func cancel_upload(){
        self.uploadimageview.hidden = true
        self.uploadimagewindow.hidden = true
        UIView.animateWithDuration(0.7, animations: {
            self.uploadimagewindow.center.y = -400
        })
        dispatch.responses_media_list.removeAllObjects()
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
        if (collectionView == self.uploaded_images){
            if let request = jobs_list[self.IndexPath.row] as? Jobs {
                count = request.requests_pics_urls.count
            }
        }else if(collectionView == self.uploadimagecollectionview){
            count = dispatch.responses_media_list.count
        }
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if (collectionView == self.uploaded_images){
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("JobsListItemImageCell",forIndexPath: indexPath)as! JobsListItemImagesViewCell
            var tempimage : Url = Url()
            if let request = jobs_list[self.IndexPath.row] as? Jobs {
                tempimage = request.requests_pics_urls[indexPath.row] as! Url
            }
            cell.loadItem(image: tempimage)
            
            return cell
        }else if(collectionView == self.uploadimagecollectionview){
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UploadedImageCell",forIndexPath: indexPath)as! UploadedImagesViewCell
            var (tempimage) = dispatch.responses_media_list[indexPath.row] as? Media
            
            cell.loadItem(image: tempimage!)
            
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if(collectionView == self.uploaded_images){
            if let request = jobs_list[self.IndexPath.row] as? Jobs {
                if((request.requests_pics_urls[indexPath.row] as? Url)!.type == "video"){
                    self.performSegueWithIdentifier("JobItemtoAVPlayerSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
                }else if((request.requests_pics_urls[indexPath.row] as? Url)!.type == "image"){
                    self.performSegueWithIdentifier("JobItemtoEnlargedPictureSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
                }
            }
        }else if(collectionView == self.uploadimagecollectionview){
            
        }
    }
    
    @IBAction func show_review(){
        self.uploadimageview.hidden = true
        self.uploadimagewindow.hidden = true
        UIView.animateWithDuration(0.7, animations: {
            self.uploadimagewindow.center.y = -400
        })
        self.performSegueWithIdentifier("JobItemtoReviewPhotosSegue", sender: nil)
    }
    
    @IBAction func skip(){
        self.uploadimageview.hidden = true
        self.uploadimagewindow.hidden = true
        UIView.animateWithDuration(0.7, animations: {
            self.uploadimagewindow.center.y = -400
        })
        dispatch.responses_media_list.removeAllObjects()
        self.show_review()
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        self.isDoneSelectingMedia = true
        var mediaType : String = info[UIImagePickerControllerMediaType] as! String
        if (mediaType == "public.movie"){
            let tempImage = info[UIImagePickerControllerMediaURL] as! NSURL!
            println(tempImage.path!)
            var data = NSData(contentsOfFile: tempImage.path!)!
            var media = Media(temptype: "video", tempdata: data, tempurl: tempImage)
            
            dispatch.responses_media_list.addObject(media)
            
            dismissViewControllerAnimated(true, completion: nil);
            self.uploadimagecollectionview.reloadData()
            //self.performSegueWithIdentifier("ShowVideoSegue", sender: self)
        }else{
            var media = Media(temptype: "image", tempdata: info[UIImagePickerControllerOriginalImage] as! UIImage)
            dispatch.responses_media_list.addObject(media)
            dismissViewControllerAnimated(true, completion: nil);
            self.uploadimagecollectionview.reloadData()
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        println("did finish picking")
        self.isDoneSelectingMedia = true
        var media = Media(temptype: "image", tempdata: image)
        dispatch.responses_media_list.addObject(media)
        dismissViewControllerAnimated(true, completion: nil);
        self.uploadimagecollectionview.reloadData()
        return
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        println("Upload Pictures!")
        self.isDoneSelectingMedia = true
        dismissViewControllerAnimated(true, completion: nil);
        self.uploadimagecollectionview.reloadData()
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

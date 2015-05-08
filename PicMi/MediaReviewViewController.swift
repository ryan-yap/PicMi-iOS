//
//  SubmissionReviewViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-23.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class MediaReviewViewCell : UICollectionViewCell {
    @IBOutlet var Picture : UIImageView!
    func loadItem(#image: Url) {
        if (image.type == "image"){
            self.Picture.image = UIImage(data: image.urldata)
            Picture.frame = CGRectMake(15,10,80,80);
        }else if(image.type == "video"){
            self.Picture.image = UIImage(named: "video.png")
            Picture.frame = CGRectMake(15,10,80,80);
        }
    }
}

class MediaReviewViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var reviewalbum: UICollectionView!
    
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var guyicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var thingicon: UIImageView!
    let picker = UIImagePickerController()
    
    var response_index : Int = Int()
    var picture_urls : NSMutableArray = NSMutableArray() //list of URL from the push notification
    var response_data = Dictionary<String, String>()
    
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
    
    @IBAction func back(){
        dispatch.responses_media_list.removeAllObjects()
        dispatch.done_reviewing_media()
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func save(){
        for x in self.picture_urls{
            var media = (x as! Url)
            
            if (media.type == "image"){
                UIImageWriteToSavedPhotosAlbum(UIImage(data: media.urldata)!, self, "image:didFinishSavingWithError:contextInfo:", nil)
            }else if(media.type == "video"){
                var paths : NSArray = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
                var documentsDirectory : NSString = paths.objectAtIndex(0) as! NSString
                var name = NSUUID().UUIDString
                var path = documentsDirectory.stringByAppendingPathComponent(name + ".mov")
                var movieURL : NSURL = NSURL(fileURLWithPath: path)!
                media.urldata.writeToFile(movieURL.path!, atomically: true)
                UISaveVideoAtPathToSavedPhotosAlbum(movieURL.path!, self, "video:didFinishSavingWithError:contextInfo:", nil)
            }
        }
        
        var jobID = self.response_data["jobID"]!
        var driver_id = self.response_data["driver_id"]!
        var requester_id = self.response_data["requester_id"]!
        
        let alertController = UIAlertController(title: "Photos saved" as String!, message: "Do you want to end this transaction?",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            dispatch.done_reviewing_media()
            var message : String = "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(jobID)"
            println(message)
            dispatch_socket.emit("endtransaction", message)
            self.dismissViewControllerAnimated(true, completion: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("CompletedTransaction", object: self, userInfo: self.response_data)
        }))
        alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            dispatch.done_reviewing_media()
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func discard(){
        dispatch.responses_media_list.removeAllObjects()
        dispatch.done_reviewing_media()
        var jobID = self.response_data["jobID"]!
        var driver_id = self.response_data["driver_id"]!
        var requester_id = self.response_data["requester_id"]!
        println(jobID)
        let alertController = UIAlertController(title: "Photos discarded" as String!, message: "Do you want to end this transaction?",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            dispatch_socket.emit("endtransaction", "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(jobID)")
            self.dismissViewControllerAnimated(true, completion: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("CompletedTransaction", object: self, userInfo: self.response_data)
        }))
        alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func image(image: UIImage, didFinishSavingWithError
        error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {
            
            if error != nil {
                // Report error to user
            }
    }
    
    func video(video: String, didFinishSavingWithError
        error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {
            if error != nil {
                println(error)
                // Report error to user
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
    
    func OnJobCancelled(notification: NSNotification){
        let alertController = UIAlertController(title: "Job Cancelled by user" as String!, message: "This job will be removed from your list",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil ))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnRequestPicmiDriverFailure(notification: NSNotification){
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
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
        super.viewDidLoad()
        
        self.response_data = ((dispatch.response_buff[self.response_index]) as! Jobs).request_dict
        self.picture_urls = ((dispatch.response_buff[self.response_index]) as! Jobs).requests_pics_urls
        dispatch.response_buff.removeObjectAtIndex(self.response_index)
        self.locationLabel.text = response_data["location_name"]
        self.picker.delegate = self
        switch (self.response_data["objecttype"]!){
        case("place"):
            self.showplaceicon()
        case("thing"):
            self.showthingicon()
        default:
            self.showguyicon()
        }
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnSubmissionSuccess:", name: "SubmissionSuccess", object: nil)
        self.reviewalbum.backgroundColor = UIColor.clearColor()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if((self.picture_urls[indexPath.row] as? Url)!.type == "video"){
            self.performSegueWithIdentifier("ReviewMediaToAVPlayerSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }else if((self.picture_urls[indexPath.row] as? Url)!.type == "image"){
            self.performSegueWithIdentifier("ReviewMediaToEnlargedPictureSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.picture_urls.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MediaReviewAlbumCell",forIndexPath: indexPath)as! MediaReviewViewCell
        var (tempimage) = self.picture_urls[indexPath.row] as? Url
        
        cell.loadItem(image: tempimage!)
        
        return cell
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "ReviewMediaToAVPlayerSegue"){
            let index = reviewalbum.indexPathForCell(sender as! MediaReviewViewCell)!
            let destination = (segue.destinationViewController as! AVPlayerViewController)
            let url = NSURL(string:
                "https://s3-us-west-1.amazonaws.com/picmi-photo" + (self.picture_urls[index.row] as? Url)!.urlpath)
            destination.player = AVPlayer(URL: url)
        }else if(segue.identifier == "ReviewMediaToEnlargedPictureSegue"){
            let index = reviewalbum.indexPathForCell(sender as! MediaReviewViewCell)!
            var media = Media(temptype: "image", tempdata: UIImage(data: (self.picture_urls[index.row] as? Url)!.urldata)!)
            (segue.destinationViewController as! EnlargedPictureViewController).Picture = media
        }
    }
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}

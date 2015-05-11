//
//  SummaryViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-07.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class UploadedImagesViewCell : UICollectionViewCell {
    @IBOutlet var Picture : UIImageView!
    func loadItem(#image: Media) {
        if (image.type == "image"){
            self.Picture.image = image.image
            Picture.frame = CGRectMake(15,10,80,80);
        }else if(image.type == "video"){
            self.Picture.image = UIImage(named: "video.png")
            Picture.frame = CGRectMake(15,10,80,80);
        }
    }
}

class SummaryViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{

    @IBOutlet var request_message: UITextView!
    @IBOutlet var uploaded_images: UICollectionView!
    
    @IBOutlet var thingicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var guyicon: UIImageView!
    @IBAction func hide_keyboard(){
        request_message.resignFirstResponder();
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
    
    func OnRequestPicmiDriverSuccess(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var distance = data["distance"] as! String!
        var uid = data["key"] as! String!
        if (dispatch.message != ""){
            data["message"] = dispatch.message
        }else{
            data["message"] = " "
        }
        data["objecttype"] = dispatch.objecttype
        data["latitude"] = "\(location.pin_latitude)"
        data["longitude"] = "\(location.pin_longitude)"
        var job_id = NSUUID().UUIDString
        data["jobID"] = "\(job_id)"
        data["location_name"] = "\(dispatch.location_name)"
        app_user.get_profile(uid)
        
        //Upload Images here. 
        for image in dispatch.requests_media_list{
            if ( (image as! Media).type == "image"){
                picture.upload_picture(uid, imagedata: (image as! Media).mediadata, count: dispatch.requests_media_list.count, dictionary: data as! Dictionary<String, String>, notification: "UploadMediaSuccess")
            }else if((image as! Media).type == "video"){
                println("Uploading Video")
                video.upload_video(uid, imagedata: (image as! Media).mediadata, count: dispatch.requests_media_list.count, dictionary: data as! Dictionary<String, String>, notification: "UploadMediaSuccess")
            }
        }
        
        if (dispatch.requests_media_list.count == 0 ){
            var new_request = Requests(request: data as! Dictionary<String, String>!, imageArray: dispatch.requests_media_list)
            requests_list.addObject(new_request);
            NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationToDriver", object: self, userInfo: data)
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func OnUploadMediaSuccess(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        var new_request = Requests(request: data as! Dictionary<String, String>!, imageArray: dispatch.requests_media_list)
        requests_list.addObject(new_request);
        dispatch.requests_media_list = NSMutableArray()
        dismissViewControllerAnimated(true, completion: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationToDriver", object: self, userInfo: data)
    }
    
    func OnRequestPicmiDriverFailure(notification: NSNotification){
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
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
    
    func OnJobCancelled(notification: NSNotification){
        let alertController = UIAlertController(title: "Job Cancelled by user" as String!, message: "This job will be removed from your list",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil ))
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
        
        switch (dispatch.objecttype){
            case("place"):
                self.showplaceicon()
            case("thing"):
                self.showthingicon()
            default:
                self.showguyicon()
        }
        
        self.request_message.text = dispatch.message!
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverSuccess:", name: "RequestPicDriverMiSuccess", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnUploadMediaSuccess:", name: "UploadMediaSuccess", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func post_to_network() {
        dispatch.message = self.request_message.text
        dispatch.request_picmi(pin_longitude: location.pin_longitude, pin_latitude: location.pin_latitude, range: 20000, filter: "")
    }

    @IBAction func cancel() {
        NSNotificationCenter.defaultCenter().postNotificationName("RequestCancelled", object: nil)
        dispatch.requests_media_list = NSMutableArray()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func showMap(){
        let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
        vc.longitude = location.pin_longitude
        vc.latitude = location.pin_latitude
        vc.location_name = dispatch.location_name
        vc.type = dispatch.objecttype
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        println("did select")
        println((dispatch.requests_media_list[indexPath.row] as? Media)!.type)
        if((dispatch.requests_media_list[indexPath.row] as? Media)!.type == "image"){
            self.performSegueWithIdentifier("SummaryToEnlargedPictureSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }else if((dispatch.requests_media_list[indexPath.row] as? Media)!.type == "video"){
            self.performSegueWithIdentifier("SummaryToAVPlayerSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //if Doneloading{
        return dispatch.requests_media_list.count
        //}
        //   return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UploadedImageCell",forIndexPath: indexPath)as! UploadedImagesViewCell
        var (tempimage) = dispatch.requests_media_list[indexPath.row] as? Media
        
        cell.loadItem(image: tempimage!)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "SummaryToEnlargedPictureSegue"){
            let index = uploaded_images.indexPathForCell(sender as! UploadedImagesViewCell)!
            (segue.destinationViewController as! EnlargedPictureViewController).Picture = (dispatch.requests_media_list[index.row] as? Media)!
        }else if(segue.identifier == "SummaryToAVPlayerSegue"){
            let index = uploaded_images.indexPathForCell(sender as! UploadedImagesViewCell)!
            let destination = (segue.destinationViewController as! AVPlayerViewController)
            let url = (dispatch.requests_media_list[index.row] as! Media).url
            destination.player = AVPlayer(URL: url)
        }
    }
}

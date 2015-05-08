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
import CoreLocation

class DriverUploadedImagesViewCell : UICollectionViewCell {
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

class DriverSummaryViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    @IBOutlet var thingicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var guyicon: UIImageView!
    @IBOutlet var request_message: UITextView!
    @IBOutlet var uploaded_images: UICollectionView!
    
    var request_index : Int = Int()
    var picture_urls : NSMutableArray = NSMutableArray() //list of URL from the push notification
    var request_data = Dictionary<String, String>()
    
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
    
    func OnRequestPicmiDriverFailure(notification: NSNotification){
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        println(request_index)
        self.request_data = ((dispatch.jobs_buff[self.request_index]) as! Jobs).request_dict
        self.picture_urls = ((dispatch.jobs_buff[self.request_index]) as! Jobs).requests_pics_urls
        dispatch.jobs_buff.removeObjectAtIndex(self.request_index)
        println(self.picture_urls)
        switch (self.request_data["objecttype"]!){
            case("place"):
                self.showplaceicon()
            case("thing"):
                self.showthingicon()
            default:
                self.showguyicon()
        }
        
        println("Driver Summary")
        self.request_message.text = self.request_data["message"]!
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func post_to_network() {
        println(self.request_data)
        var driver_id = self.request_data["driver_id"]!
        var jobID = self.request_data["jobID"]!
        var requester_id = self.request_data["requester_id"]!
        var message = "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(jobID)"
        dispatch_socket.emit("acceptrequest", message)
        var new_request = Jobs(request: self.request_data, urlsArray: self.picture_urls);
        jobs_list.addObject(new_request);
        NSNotificationCenter.defaultCenter().postNotificationName("PinLocation", object: self, userInfo: self.request_data)
        dispatch.reset();
        picture.reset();
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel() {
        var driver_id = self.request_data["driver_id"]!
        var jobID = self.request_data["jobID"]!
        var requester_id = self.request_data["requester_id"]!
        var message = "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(jobID)"
        dispatch_socket.emit("declinerequest", message)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func showMap(){
        let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
        vc.longitude = CLLocationDegrees((self.request_data["longitude"] as NSString!).doubleValue)
        vc.latitude = CLLocationDegrees((self.request_data["latitude"] as NSString!).doubleValue)
        vc.location_name = self.request_data["location_name"] as String!
        vc.type = self.request_data["objecttype"] as String!
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if((self.picture_urls[indexPath.row] as? Url)!.type == "video"){
            self.performSegueWithIdentifier("DriverSummaryToAVPlayer", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }else if((self.picture_urls[indexPath.row] as? Url)!.type == "image"){
            self.performSegueWithIdentifier("DriverSummaryToEnlargedPicture", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.picture_urls.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("DriverUploadedImageCell",forIndexPath: indexPath)as! DriverUploadedImagesViewCell
        var (tempimage) = self.picture_urls[indexPath.row] as? Url
        
        cell.loadItem(image: tempimage!)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "DriverSummaryToAVPlayer"){
            let index = uploaded_images.indexPathForCell(sender as! DriverUploadedImagesViewCell)!
            let destination = (segue.destinationViewController as! AVPlayerViewController)
            let url = NSURL(string:
                "https://s3-us-west-1.amazonaws.com/picmi-photo" + (self.picture_urls[index.row] as? Url)!.urlpath)
            destination.player = AVPlayer(URL: url)
        }else if(segue.identifier == "DriverSummaryToEnlargedPicture"){
            let index = uploaded_images.indexPathForCell(sender as! DriverUploadedImagesViewCell)!
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

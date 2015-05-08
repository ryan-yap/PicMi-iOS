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

class SubmissionImagesViewCell : UICollectionViewCell {
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

class SubmissionReviewViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet var reviewalbum: UICollectionView!
    
    @IBOutlet var guyicon: UIImageView!
    @IBOutlet var placeicon: UIImageView!
    @IBOutlet var thingicon: UIImageView!
    var IndexPath : NSIndexPath = NSIndexPath()
    
    @IBOutlet var locationLabel: UILabel!
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
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func submit_photos(){
        if let request = jobs_list[self.IndexPath.row] as? Jobs {
            println(request.request_dict)
            var dict : Dictionary = Dictionary<String, String>()
            dict["driver_id"] = request.request_dict["driver_id"]
            dict["requester_id"] = request.request_dict["requester_id"]
            dict["message"] = request.request_dict["message"]
            dict["objecttype"] = request.request_dict["objecttype"]
            dict["jobID"] = request.request_dict["jobID"]
            dict["location_name"] = request.request_dict["location_name"]
            for image in dispatch.responses_media_list{
                if ( (image as! Media).type == "image"){
                    picture.upload_picture(dict["requester_id"]!, imagedata: (image as! Media).mediadata, count: dispatch.responses_media_list.count, dictionary: dict, notification: "SubmissionSuccess")
                }else if((image as! Media).type == "video"){
                    println("Uploading Video")
                    video.upload_video(dict["requester_id"]!, imagedata: (image as! Media).mediadata, count: dispatch.responses_media_list.count, dictionary: dict, notification: "SubmissionSuccess")
                }
            }
        }
    }
    
    func OnSubmissionSuccess(notification: NSNotification){
        var data = notification.userInfo as Dictionary!
        NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationToUser", object: self, userInfo: data)
        dispatch.done_submitting_media()
        dismissViewControllerAnimated(true, completion: nil)
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
        let alertController = UIAlertController(title: "Driver Not Found" as String!, message: "Please try again later",   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func OnJobCancelled(notification: NSNotification){
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoRequest:", name: "PhotoRequest", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnPhotoResponse:", name: "PhotoResponse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnRequestPicmiDriverFailure:", name: "RequestPicMiDriverFailure", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnJobCancelled:", name: "JobCancelled", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReceivedMessage:", name: "MessageReceiveNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnTransactionEnded:", name: "transactionended", object: nil)
        if let request = jobs_list[self.IndexPath.row] as? Jobs {
            switch (request.request_dict["objecttype"]!){
            case("place"):
                self.showplaceicon()
            case("thing"):
                self.showthingicon()
            default:
                self.showguyicon()
            }
            self.locationLabel.text = request.request_dict["location_name"] as String!
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnSubmissionSuccess:", name: "SubmissionSuccess", object: nil)
        self.reviewalbum.backgroundColor = UIColor.clearColor()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        println((dispatch.responses_media_list[indexPath.row] as? Media)!.type)
        if((dispatch.responses_media_list[indexPath.row] as? Media)!.type == "image"){
            self.performSegueWithIdentifier("SubmissionToEnlargedPictureSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }else if((dispatch.responses_media_list[indexPath.row] as? Media)!.type == "video"){
            self.performSegueWithIdentifier("SubmissionToAVPlayerSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dispatch.responses_media_list.count

    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SubmissionsAlbumCell",forIndexPath: indexPath)as! SubmissionImagesViewCell
        var (tempimage) = dispatch.responses_media_list[indexPath.row] as? Media
        
        cell.loadItem(image: tempimage!)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "SubmissionToEnlargedPictureSegue"){
            let index = reviewalbum.indexPathForCell(sender as! SubmissionImagesViewCell)!
            (segue.destinationViewController as! EnlargedPictureViewController).Picture = (dispatch.responses_media_list[index.row] as? Media)!
        }else if(segue.identifier == "SubmissionToAVPlayerSegue"){
            let index = reviewalbum.indexPathForCell(sender as! SubmissionImagesViewCell)!
            let destination = (segue.destinationViewController as! AVPlayerViewController)
            let url = (dispatch.responses_media_list[index.row] as! Media).url
            destination.player = AVPlayer(URL: url)
        }
    }
}

//
//  ViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-05-11.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class LoadingViewController: UIViewController {

    @IBOutlet var flashview: UIView!
    @IBOutlet var LoadingImage: UIImageView!
    var capturesound = AVAudioPlayer()
    
    func OnGPSActivated(notification: NSNotification){
        UIView.animateWithDuration(0.01, delay: 0.1, options: UIViewAnimationOptions.Autoreverse, animations: {
            self.capturesound.play();
            self.flashview.alpha = 1;
            }, completion: { finished in
                //self.flashview.alpha = 0;
                self.performSegueWithIdentifier("toMainSegue", sender: nil)
        })
    }
    
    func setupAudioPlayerWithFile(file:NSString, type:NSString) -> AVAudioPlayer  {
        var path = NSBundle.mainBundle().pathForResource(file as String, ofType:type as String)
        var url = NSURL.fileURLWithPath(path!)
        
        var error: NSError?
        
        var audioPlayer:AVAudioPlayer?
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        
        return audioPlayer!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.capturesound = self.setupAudioPlayerWithFile("capture", type:"mp3")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnGPSActivated:", name: "GPSActivated", object: nil)
        var imageData = NSData(contentsOfURL: NSBundle.mainBundle()
            .URLForResource("loader", withExtension: "gif")!)
        let loading = UIImage.animatedImageWithData(imageData!)
        self.LoadingImage.image = loading
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

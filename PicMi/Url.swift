//
//  Url.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-20.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation

class Url{
    var type : String = ""
    var urlpath : String = ""
    var urldata : NSData = NSData()
    
    init(temptype:String, tempurl: String){
        self.type = temptype
        self.urlpath = tempurl
        self.urldata = NSData(contentsOfURL: NSURL(string:"https://s3-us-west-1.amazonaws.com/picmi-photo" + tempurl)!)!
    }
 
    init(){
        
    }

}
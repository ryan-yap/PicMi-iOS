//
//  Media.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-20.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation

class Media{
    var type : String = ""
    var mediadata : NSData = NSData()
    var image : UIImage = UIImage()
    var url : NSURL = NSURL()
    var dir : String = ""
    var id : String = ""
    
    init(temptype:String, tempdata: NSData, tempurl : NSURL){
        self.type = temptype
        self.mediadata = tempdata
        self.url = tempurl
    }
    
    init(temptype: String, tempdata: UIImage){
        self.type = temptype
        self.mediadata = UIImageJPEGRepresentation(tempdata, 1)!
        self.image = tempdata
        
    }
    
    init(){
        
    }
    
    func save_to_file(){
        if(self.type == "video"){
            var media_id = NSUUID().UUIDString
            self.dir = "/user/video/\(media_id)"
        }else if(self.type == "image"){
            var media_id = NSUUID().UUIDString
            self.dir = "/user/photo/\(media_id)"
        }
    }
}
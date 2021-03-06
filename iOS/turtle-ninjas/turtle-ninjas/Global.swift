//
//  Global.swift
//  turtle-ninjas
//
//  Created by Vitor Oliveira on 5/20/16.
//  Copyright © 2016 Vitor Oliveira. All rights reserved.
//

import UIKit
import SwiftHTTP
import SwiftyJSON

enum HTTPTYPE {
    case GET, PUT, DELETE, POST
}

public class Global {

    public var base_url = "http://turtle-ninjas.herokuapp.com"
    
    func request(url: String, params: Dictionary<String,AnyObject>?, headers: Dictionary<String,String>?, type: HTTPTYPE, completion:(JSON) -> Void)  {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            do {
               
                //get as default
                var opt = try HTTP.GET(url, parameters: params, headers: headers)
                
                switch type {
                    case .GET:
                        opt = try HTTP.GET(url, parameters: params, headers: headers)
                    case .PUT:
                        opt = try HTTP.PUT(url, parameters: params, headers: headers)
                    case .DELETE:
                        opt = try HTTP.DELETE(url, parameters: params, headers: headers)
                    case .POST:
                        opt = try HTTP.POST(url, parameters: params, headers: headers)
                }
                
                opt.start { response in
                
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return
                    }
                    
                    do {
                        let object:AnyObject? = try NSJSONSerialization.JSONObjectWithData(response.data, options: .AllowFragments)
                        let json = JSON(object!)
                        return completion(json)
                    } catch _ as NSError {
                        return
                    }
                    
                }
                
            } catch let error {
                print("got an error creating the request: \(error)")
            }
            
        })
    }

}

// Image caching
class MyImageCache {
    
    static let sharedCache: NSCache = {
        let cache = NSCache()
        cache.name = "MyImageCache"
        cache.countLimit = 20
        cache.totalCostLimit = 10*1024*1024
        return cache
    }()
    
}

extension NSURL {
    
    typealias ImageCacheCompletion = UIImage -> Void
    
    var cachedImage: UIImage? {
        return MyImageCache.sharedCache.objectForKey(
            absoluteString) as? UIImage
    }
    
    func fetchImage(completion: ImageCacheCompletion) {
        let task = NSURLSession.sharedSession().dataTaskWithURL(self) {
            data, response, error in
            if error == nil {
                if let  data = data,
                    image = UIImage(data: data) {
                    MyImageCache.sharedCache.setObject(
                        image,
                        forKey: self.absoluteString,
                        cost: data.length)
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(image)
                    }
                }
            }
        }
        task.resume()
    }
    
}

extension Float {
    func format(fractionDigits: Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.stringFromNumber(self) ?? "\(self)"
    }
}
//
//  FlickrApiService.swift
//  PixelCity
//
//  Created by Iain Coleman on 27/11/2017.
//  Copyright © 2017 Fiendish Corporation. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON

class FlickrApiService {
    
    static let instance = FlickrApiService()
    
    //enum for json keys
    enum jsonKeys: String {
        case photos
        case photo
        case farm
        case server
        case id
        case secret
    }
    
    
    //Variables
    public private(set) var imageUrlArray = [String]()
    public private(set) var imageArray = [UIImage]()
    public private(set) var progressLabel = String()
    
    
    func flickrUrl(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
        
        let fullUrl = "\(BASE_URL)\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
        return fullUrl
    }
    
    
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, completion: @escaping (_ status: Bool) -> ()) {
        Alamofire.request(flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.result.value as? Dictionary<String, AnyObject> else { return }
                let photosDict = data[jsonKeys.photos.rawValue] as! Dictionary<String, AnyObject>
                let photosDictArray = photosDict[jsonKeys.photo.rawValue] as! [Dictionary<String, AnyObject>]
                
                
                for photo in photosDictArray {
                    let postUrl = "https://farm\(photo[jsonKeys.farm.rawValue]!).staticflickr.com/\(photo[jsonKeys.server.rawValue]!)/\(photo[jsonKeys.id.rawValue]!)_\(photo[jsonKeys.secret.rawValue]!)_h_d.jpg"
                    self.imageUrlArray.append(postUrl)
                }
                completion(true)
            } else {
                debugPrint(response.result.error as Any)
                completion(false)
            }
        }
    }
    
    
    
    func retrieveImages(completion: @escaping (_ status: Bool) -> ()) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                
                if response.result.error == nil {
                    guard let image = response.result.value else { return }
                    self.imageArray.append(image)
                    self.progressLabel = "\(self.imageArray.count)/40 images downloaded"
                    NotificationCenter.default.post(name: NOTIF_UPDATE_PROGRESS_LBL, object: nil)
                    if self.imageArray.count == self.imageUrlArray.count {
                        completion(true)
                    }
                }
            })
        }
    }
    
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({$0.cancel() })
            downloadData.forEach({$0.cancel()})
        }
    }
    
    
    func emptyArrays() {
        self.imageArray.removeAll()
        self.imageUrlArray.removeAll()
    }
    
}

//
//  FlickrSearchResponse.swift
//  FlickrImageSearchApp
//
//

import Foundation

typealias JSONObject = Dictionary<String, AnyObject>

// This class converts NSData to JSON object and parses it to create an array of items that are shown as a grid in HomeViewController(Collection View)
class FlickrSearchResponse {
    
    var items:[FlickrObject] = [FlickrObject]() // Items
    
    init?(data:NSData) {
        
        var newItems = [FlickrObject]()
        
        var json:JSONObject?
        
        do {
            json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? JSONObject
        }
        catch {
            print("NSData to Dictionary conversion failed")
        }
        
        guard let jsonObject = json else {
            return nil
        }
        
        // Parsing starts according to JSON response
        guard let photos = jsonObject["photos"] as? JSONObject else {
            return
        }
        
        guard let photoArray = photos["photo"] as? [JSONObject] else {
            return
        }
        
        for item in photoArray {
            guard let id = item["id"] as? String else {
                continue
            }
            
            guard let urlString = item["url_s"] as? String, url = NSURL(string:urlString) else {
                continue
            }
            
            guard let height = item["height_s"] as? String, heightIntValue = Int(height) else {
                continue
            }
            
            let title = item["title"] as? String ?? ""
            let tagsArray = (item["tags"] as? String)?.componentsSeparatedByString(" ")

            newItems.append(FlickrObject(id: id, imageUrl: url, title: title, tags: tagsArray, height: heightIntValue))
        }
        
        self.items = newItems
    }
}

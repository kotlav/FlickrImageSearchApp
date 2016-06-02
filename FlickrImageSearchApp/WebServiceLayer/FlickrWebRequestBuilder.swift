//
//  FlickrRequestBuilder.swift
//  FlickrImageSearchApp
//
//

import Foundation

// This enum is used to return NSURLRequest for two web service tasks in the app.

enum FlickrWebRequestBuilder {
    case SearchByTag(String) 
    case DownloadImageByUrlString(NSURL)
    
    var urlRequest:NSMutableURLRequest? {
        
        var request:NSMutableURLRequest?
        
        switch self {
        case .SearchByTag(let tag) :
            let baseUrlString = "https://api.flickr.com/services/rest/"
            let urlComponents = NSURLComponents(string: baseUrlString)
            urlComponents?.queryItems = [
                //NSURLQueryItem(name: "per_page", value: "30"),
                NSURLQueryItem(name: "format", value: "json"),
                NSURLQueryItem(name: "nojsoncallback", value: "1"),
                NSURLQueryItem(name: "api_key", value: AppVariables.apiKey),
                NSURLQueryItem(name: "method", value: "flickr.photos.search"),
                NSURLQueryItem(name: "extras", value: "tags,media,url_s,o_dims"),
                NSURLQueryItem(name: "tags", value: tag)
            ]
            guard let url = urlComponents?.URL else {
                return nil
            }
            
            request = NSMutableURLRequest(URL: url)
            request?.timeoutInterval = 120
            
            request?.HTTPMethod = "GET"
            
            return request
            
        case .DownloadImageByUrlString(let url) :
            
            request = NSMutableURLRequest(URL: url)
            request?.timeoutInterval = 120
            
            request?.HTTPMethod = "GET"
            
            return request
        }
    }
}
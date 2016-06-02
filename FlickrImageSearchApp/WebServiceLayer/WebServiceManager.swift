//
//  WebServiceManager.swift
//  FlickrImageSearchApp
//
//

import Foundation

typealias FlickrURLSessionCompletionBlock = (NSData?, NSURLResponse?, NSError?) -> Void

// Defines rules for fetching data from flickr server
protocol FlickrWebServiceProtocol {
    var dataTask:NSURLSessionDataTask? {get set}
    mutating func dataFromFlickrService(completionHandler:FlickrURLSessionCompletionBlock)
    func cancelTask()
}

extension FlickrWebServiceProtocol {
    // This function checks whether data task is in Running state and cancels accordingly
    func cancelTask() {
        if let task = dataTask where task.state == .Running {
            task.cancel()
        }
    }
}

// This struct helps in downloading images from flickr server
struct FlickrDownloadImageServiceTask:FlickrWebServiceProtocol {
    
    let imageUrl:NSURL
    
    var dataTask:NSURLSessionDataTask?
    
    init(imageUrl:NSURL) {
        self.imageUrl = imageUrl
    }

    mutating func dataFromFlickrService(completionHandler:FlickrURLSessionCompletionBlock) {
        guard let urlRequest = FlickrWebRequestBuilder.DownloadImageByUrlString(imageUrl).urlRequest else {
            return
        }
        dataTask = WebServiceManager.dataForUrlRequest(urlRequest) {
            (data, response, error) in
            completionHandler(data, response, error)
        }
    }
}

// This struct helps in downloading json from flickr server
struct FlickrSeachByTagServiceTask:FlickrWebServiceProtocol {
    
    let tag:String
    
    var dataTask:NSURLSessionDataTask?
    
    init(tag:String) {
        self.tag = tag
    }
    
    mutating func dataFromFlickrService(completionHandler:FlickrURLSessionCompletionBlock) {
        guard let urlRequest = FlickrWebRequestBuilder.SearchByTag(tag).urlRequest else {
            return
        }
        dataTask = WebServiceManager.dataForUrlRequest(urlRequest) {
            (data, response, error) in
            completionHandler(data, response, error)
        }
    }
}

// This struct can be used throughout the app to create different data tasks
struct WebServiceManager {
    static let urlSession:NSURLSession = NSURLSession.sharedSession()
    
    static func dataForUrlRequest(request:NSURLRequest, completionHandler: FlickrURLSessionCompletionBlock) -> NSURLSessionDataTask {
        let task = urlSession.dataTaskWithRequest(request) { (data, response, error) in
            completionHandler(data, response, error)
        }
        
        task.resume()
        
        return task
    }
}
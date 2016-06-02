//
//  FlickrObject.swift
//  FlickrImageSearchApp
//
//

import Foundation

// MARK: Search Response Object
// This struct acts as POJO for search response, and View Model(VM) for Collection View Cell
struct FlickrObject {
    var id:String
    var imageUrl:NSURL
    var title:String
    var tags:[String]?
    var height:Int
}
//
//  JsonableApi.swift
//  Jsonable
//
//  Created by Lee Whitney on 10/15/14.
//  Copyright (c) 2014 WhitneyLand. All rights reserved.
//
import Foundation


class Api<T:Jsonable> : SequenceType {
    
    init() {
        headers["Content-Type"] = "application/json"    
    }
    
    var entityList : [T] = []
    var baseUrl: String = ""
    var headers = Dictionary<String, String>()
    
    func entityBaseUrl() -> NSURL {
        var url = "\(baseUrl)\(T.urlName())"
        return NSURL(string:url)!
    }
    
    func entityUrl(id: String) -> NSURL {
        var url = "\(baseUrl)\(T.urlName())/\(id)"
        return NSURL(string:url)!
    }
    
    //
    // Get an array of Json objects and deserialize them to Swift
    //
    func get(completionHandler: ((result: HttpResult) -> Void)!) {

        Http().get(self.entityBaseUrl(), headers: headers) { (result) in
            
            var error: NSError?
            if let jsonArray: AnyObject? = NSJSONSerialization.JSONObjectWithData(result.data!,
                options: .AllowFragments, error: &error) as AnyObject! {
                self.entityList = self.jsonArrayToSwiftArray(jsonArray as NSArray)
            }
            
            // If successful fire global event handler
            if result.headers["Content-Type"]!.contains("application/json") {
                if let resultJsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(result.data!, options: .AllowFragments, error: &error) as AnyObject? {
                    for index in 0..<self.entityList.count {
                        var entity = self.entityList[index]
                        self.getResponse(index, entity: entity, resultJsonObject: resultJsonObject, result: result)
                    }
                }
            }

            completionHandler(result: result)
        }
    }

    //
    // Get a single Json object and deserialize it to Swift
    //
    func get(id: String, completionHandler: ((result: HttpResult) -> Void)!) {

        Http().get(self.entityUrl(id), headers: headers) { (result) in

            let entity = self.createType()
            entity.fromJsonData(result.data!)
            self.entityList.append(entity)
            
            // If successful fire global event handler
            var error: NSError?            
            if result.headers["Content-Type"]!.contains("application/json") {
                if let resultJsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(result.data!, options: .AllowFragments, error: &error) as AnyObject? {
                    for index in 0..<self.entityList.count {
                        var entity = self.entityList[index]
                        self.getResponse(index, entity: entity, resultJsonObject: resultJsonObject, result: result)
                    }
                }
            }
            
            completionHandler(result: result)
        }
    }

    func get(id: Int, completionHandler: ((result: HttpResult) -> Void)!) {        
        get("\(id)") { (result) in
            completionHandler(result: result)
        }
    }
    
    //
    // Post Json from array of serialized Swift objects
    //
    func post(completionHandler: ((result: HttpResult) -> Void)!) {
        
        var error: NSError?
        var jsonArray = swiftArrayToJsonArray()
        var jsonData = NSJSONSerialization.dataWithJSONObject(jsonArray, options: NSJSONWritingOptions.PrettyPrinted, error: &error)

        Http().post(self.entityBaseUrl(), headers: headers, data:jsonData!) { (result) in
            
            // After getting result, allow for post processing            
            if result.headers["Content-Type"]!.contains("application/json") {
                if let resultJsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(result.data!, options: .AllowFragments, error: &error) as AnyObject? {
                        for index in 0..<self.entityList.count {
                        var entity = self.entityList[index]
                        self.postResponse(index, entity: entity, resultJsonObject: resultJsonObject, result: result)
                    }
                }
            }
            completionHandler(result: result)
        }
    }

    //
    // Update Json from array of serialized Swift objects
    //
    func put(completionHandler: ((result: HttpResult) -> Void)!) {
        
        var error: NSError?
        var jsonArray = swiftArrayToJsonArray()
        var jsonData = NSJSONSerialization.dataWithJSONObject(jsonArray, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        Http().put(self.entityBaseUrl(), headers: headers, data:jsonData!) { (result) in
            
            // After getting result, allow for post processing
            if result.headers["Content-Type"]!.contains("application/json") {
                if let resultJsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(result.data!, options: .AllowFragments, error: &error) as AnyObject? {
                    for index in 0..<self.entityList.count {
                        var entity = self.entityList[index]
                        self.putResponse(index, entity: entity, resultJsonObject: resultJsonObject, result: result)
                    }
                }
            }
            completionHandler(result: result)
        }
    }
    
    //
    // Delete Json based on array of serialized Swift objects
    //
    func delete(completionHandler: ((result: HttpResult) -> Void)!) {
        
        var error: NSError?
        var jsonArray = swiftArrayToJsonArray()
        var jsonData = NSJSONSerialization.dataWithJSONObject(jsonArray, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        Http().delete(self.entityBaseUrl(), headers: headers, data:jsonData!) { (result) in
            
            // If successful fire global event handler
            if result.headers["Content-Type"]!.contains("application/json") {
                if let resultJsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(result.data!, options: .AllowFragments, error: &error) as AnyObject? {
                    for index in 0..<self.entityList.count {
                        var entity = self.entityList[index]
                        self.deleteResponse(index, entity: entity, resultJsonObject: resultJsonObject, result: result)
                    }
                }
            }
            completionHandler(result: result)
        }
    }
    
    // -----------------------------
    // Global event handlers 
    // Virtual methods will be called when overriden
    //
    
    // Client can update Swift objects with any newly created Id's returned from POST
    func getResponse(index: Int, entity: Jsonable, resultJsonObject: AnyObject, result: HttpResult) {
    }

    func postResponse(index: Int, entity: Jsonable, resultJsonObject: AnyObject, result: HttpResult) {
    }
    
    func putResponse(index: Int, entity: Jsonable, resultJsonObject: AnyObject, result: HttpResult) {
    }
    
    func deleteResponse(index: Int, entity: Jsonable, resultJsonObject: AnyObject, result: HttpResult) {
    }
    
    func jsonArrayToSwiftArray(jsonArray: NSArray) -> [T] {
        var entityList : [T] = []
        for jsonDictionary in jsonArray {
            let entity = createType()
            entity.fromJsonDictionary(jsonDictionary as NSDictionary)
            entityList.append(entity as T)
        }
        return entityList
    }
    
    func swiftArrayToJsonArray() -> NSArray {
        var array = NSMutableArray()

        for entity in entityList {
            var jsonDictionary = entity.toJsonDictionary()
            array.addObject(jsonDictionary)
        }
        return array
    }
    
    // Enable for-in iteration
    func generate() -> GeneratorOf<T> {
        var nextIndex = entityList.count-1
        return GeneratorOf<T> {
            if (nextIndex < 0) {
                return nil
            }
            return self.entityList[nextIndex--]
        }
    }
    
    // Enable array style access
    subscript(index: Int) -> T {
        get {
            return entityList[index]
        }
        set(newMessage) {
            entityList[index] = newMessage
        }
    }
    
    func append(newEntity : T) {
        entityList.append(newEntity)
    }
    
    // Work around for Swift generics not supporting virtual constructors
    // http://stackoverflow.com/questions/26280176/swift-generics-not-preserving-type
    func createType() -> T {
        return T.createInstance() as T
    }
}

//
//  Project.swift
//  AutomaticWriter
//
//  Created by Raphael on 14.01.15.
//  Copyright (c) 2015 HEAD Geneva. All rights reserved.
//

import Cocoa

class Project: NSObject {
    
    var path : String
    var folderName : String
    
    init(projectPath : String) {
        path = projectPath
        folderName = (path as NSString).lastPathComponent
        
        super.init()
    }
    
    func addFilesInFolderPath(folderPath:String, intoArray:NSMutableArray) {
        let absolutePath = (path as NSString).stringByAppendingPathComponent(folderPath)
        
        if let content:NSArray = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(absolutePath) {
            for file in content {
                if let fileName = file as? String {
                    if fileName[fileName.startIndex] == "." {
                        print("ignore invisible file: \(fileName)")
                    } else if fileName == "automat" {
                        print("ignore automat folder")
                    } else {
                        
                        let fileRelativePath = (folderPath as NSString).stringByAppendingPathComponent(fileName)
                        let fileAbsolutePath = (absolutePath as NSString).stringByAppendingPathComponent(fileName)
                        
                        var isDir = ObjCBool(false)
                        if NSFileManager.defaultManager().fileExistsAtPath(fileAbsolutePath, isDirectory: &isDir) {
                            if isDir.boolValue {
                                //println("\(absolutePath) is a folder")
                                // recursively add files
                                addFilesInFolderPath(fileRelativePath, intoArray: intoArray)
                            } else {
                                //println("adding file: \(fileName)")
                                if let attributes : [NSObject : AnyObject] = try? NSFileManager.defaultManager().attributesOfItemAtPath(fileAbsolutePath) {
                                    
                                    let date:NSDate? = attributes[NSFileModificationDate] as? NSDate
                                    if date == nil {
                                        print("\(self.className):addFilesInFolderPath: date is nil, we're stopping the process to avoid unattended behaviours")
                                        return
                                    }
                                    
                                    let fileRelativePathInBook = (folderName as NSString).stringByAppendingPathComponent(fileRelativePath)
                                    let dico:NSDictionary = ["path": fileRelativePathInBook, "date": date!]
                                    
                                    intoArray.addObject(dico)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            print("can't find content at path: \(absolutePath)")
        }
    }
    
    func getArrayOfFiles() -> NSArray {
        let array : NSMutableArray = []
        addFilesInFolderPath("", intoArray: array)
        return array
    }
    
    func getArrayOfFilesAsNSData() -> NSData {
        let array = getArrayOfFiles()
        let data:NSData = NSKeyedArchiver.archivedDataWithRootObject(array)
        return data
    }
}

//
//  AutomatFileManager.swift
//  AutomaticWriter
//
//  Created by Raphael on 20.01.15.
//  Copyright (c) 2015 HEAD Geneva. All rights reserved.
//

import Cocoa

protocol AutomatFileManagerDelegate {
    func onFilesAdded(files:[String]);
}

class AutomatFileManager: NSObject {
    
    // ==================================================================
    // MARK: ************   Object functions (instance)   ************
    // ==================================================================
    
    var delegate:AutomatFileManagerDelegate?
    var rootFolderPath:String
    
    /// Initialize with the path of the root folder of the project
    ///
    /// - parameter _rootFolderPath: path of the folder root
    init(_rootFolderPath:String) {
        rootFolderPath = _rootFolderPath
        super.init()
    }
    
    // ==================================================================
    // MARK: * File Creation
    
    /// Create a file in current project using root folder path
    /// File types have strict paths, described in "* Default files destinations" and "* Default directories for files"
    ///
    /// - parameter type: "Automatic Writing", "HTML", "css" or "javascript"
    func createNewFileOfType(type:String) {
        var directory:String?
        var defaultFileToCopy:String?
        var destinationPath:String?
        
        if type == "Automatic Writing" {
            directory = automatDirectory()
            defaultFileToCopy = AutomatFileManager.automatDefaultFile()
            let fileDestination = automatFileDestination(nil)
            if let actualFileDestination = fileDestination {
                destinationPath = AutomatFileManager.getValidDestinationPathForFile(actualFileDestination)
            }
        }
        else if type == "HTML" {
            directory = htmlDirectory()
            defaultFileToCopy = AutomatFileManager.htmlDefaultFile()
            let fileDestination = htmlFileDestination(nil)
            if let actualFileDestination = fileDestination {
                destinationPath = AutomatFileManager.getValidDestinationPathForFile(actualFileDestination)
            }
        }
        else if type == "css" {
            directory = cssDirectory()
            defaultFileToCopy = AutomatFileManager.cssDefaultFile()
            let fileDestination = cssFileDestination(nil)
            if let actualFileDestination = fileDestination {
                destinationPath = AutomatFileManager.getValidDestinationPathForFile(actualFileDestination)
            }
        }
        else if type == "javascript" {
            directory = javascriptDirectory()
            defaultFileToCopy = AutomatFileManager.javascriptDefaultFile()
            let fileDestination = javascriptFileDestination(nil)
            if let actualFileDestination = fileDestination {
                destinationPath = AutomatFileManager.getValidDestinationPathForFile(actualFileDestination)
            }
        }
        else {
            print("\(self.className): Error: we can only create new Automatic Writing, HTML, css and javascript files")
            return
        }
        
        // block attemps if we don't have all the informations needed
        if directory == nil {
            print("\(self.className): Error: missing directory to create new file of type \(type)")
            return
        }
        if defaultFileToCopy == nil {
            print("\(self.className): Error: missing defaultFileToCopy to create new file of type \(type)")
            return
        }
        if destinationPath == nil {
            print("\(self.className): Error: missing destinationPath to create new file of type \(type)")
            return
        }
        
        AutomatFileManager.createDirectoryAtPath(directory!)
        
        if AutomatFileManager.createFileAtPath(destinationPath!, fromFile: defaultFileToCopy!) {
            let file:[String] = [destinationPath!]
            // tell the delegate we added a file
            delegate?.onFilesAdded(file)
        }
    }
    
    /// Copy files from an array of paths (Strings).
    /// It puts them in the right place according to default directories by type
    /// and makes sure there's never twice the same name
    ///
    /// - parameter files: array of paths
    func copyFilesFromArray(files:[String]) {
        var fileSuccessfullyCopied:[String] = []
        
        for path in files {
            // TODO: fix the copy for images
            if AutomatFileManager.fileAtPathIsAnImage(path) {
                // create directory
                AutomatFileManager.createDirectoryAtPath(imageDirectory())
                
                // get destination
                let destination = imageFileDestination((path as NSString).lastPathComponent)
                if let actualDestination = destination {
                    
                    // add suffixe to destination if necessary
                    let validDestination = AutomatFileManager.getValidDestinationPathForFile(actualDestination)
                    if let actualValidDestination = validDestination {
                        
                        // create file
                        if AutomatFileManager.createFileAtPath(actualValidDestination, fromFile: path) {
                            fileSuccessfullyCopied += [actualValidDestination]
                        }
                    }
                }
            }
            
            else if AutomatFileManager.fileAtPathIsAnAudiovisualContent(path) {
                // just ignore it, we don't manage that for now
            }
            
            else if AutomatFileManager.fileAtPathIsATextFile(path) {
                let fileName = (path as NSString).lastPathComponent
                var destination:String?
                
                switch (path as NSString).pathExtension {
                case "html":
                    AutomatFileManager.createDirectoryAtPath(htmlDirectory())
                    let tempDestination = htmlFileDestination(fileName)
                    if let actualTempDestination = tempDestination {
                        destination = AutomatFileManager.getValidDestinationPathForFile(actualTempDestination)
                    }
                    break
                case "css":
                    AutomatFileManager.createDirectoryAtPath(cssDirectory())
                    let tempDestination = cssFileDestination(fileName)
                    if let actualTempDestination = tempDestination {
                        destination = AutomatFileManager.getValidDestinationPathForFile(actualTempDestination)
                    }
                    break
                case "js":
                    AutomatFileManager.createDirectoryAtPath(javascriptDirectory())
                    let tempDestination = javascriptFileDestination(fileName)
                    if let actualTempDestination = tempDestination {
                        destination = AutomatFileManager.getValidDestinationPathForFile(actualTempDestination)
                    }
                    break
                case "automat":
                    AutomatFileManager.createDirectoryAtPath(automatDirectory())
                    let tempDestination = automatFileDestination(fileName)
                    if let actualTempDestination = tempDestination {
                        destination = AutomatFileManager.getValidDestinationPathForFile(actualTempDestination)
                    }
                    break
                default:
                    break
                }
                
                if destination == nil {
                    continue
                }
                
                if AutomatFileManager.createFileAtPath(destination!, fromFile: path) {
                    fileSuccessfullyCopied += [destination!]
                }
            }
        }
        
        // tell the delegate we added files
        delegate?.onFilesAdded(fileSuccessfullyCopied)
    }
    
    // ==================================================================
    // MARK: * Default files destinations
    
    /// Get the default destination path for ".automat" files in the project (owner) and adds the fileName at the end
    /// or the default name if fileName is nil
    ///
    /// - parameter fileName: name you want to give to the file
    /// - returns: the complete path
    func automatFileDestination(fileName:String?) -> String? {
        if fileName == "" || fileName == nil {
            if let defaultFile = AutomatFileManager.automatDefaultFile() {
                let defaultName = (defaultFile as NSString).lastPathComponent
                return (automatDirectory() as NSString).stringByAppendingPathComponent(defaultName)
            } else {
                print("couldn't retrieve default name for automat file")
                return nil
            }
        } else {
            return (automatDirectory() as NSString).stringByAppendingPathComponent(fileName!)
        }
    }
    
    /// Get the default destination path for ".css" files in the project (owner) and adds the fileName at the end
    /// or the default name if fileName is nil
    ///
    /// - parameter fileName: name you want to give to the file
    /// - returns: the complete path
    func cssFileDestination(fileName:String?) -> String? {
        if fileName == "" || fileName == nil {
            if let defaultFile = AutomatFileManager.cssDefaultFile() {
                let defaultName = (defaultFile as NSString).lastPathComponent
                return (cssDirectory() as NSString).stringByAppendingPathComponent(defaultName)
            } else {
                print("couldn't retrieve default name for css file")
                return nil
            }
        } else {
            return (cssDirectory() as NSString).stringByAppendingPathComponent(fileName!)
        }
    }
    
    /// Get the default destination path for ".js" files in the project (owner) and adds the fileName at the end
    /// or the default name if fileName is nil
    ///
    /// - parameter fileName: name you want to give to the file
    /// - returns: the complete path
    func javascriptFileDestination(fileName:String?) -> String? {
        if fileName == "" || fileName == nil {
            if let defaultFile = AutomatFileManager.javascriptDefaultFile() {
                let defaultName = (defaultFile as NSString).lastPathComponent
                return (javascriptDirectory() as NSString).stringByAppendingPathComponent(defaultName)
            } else {
                print("couldn't retrieve default name for javascript file")
                return nil
            }
        } else {
            return (javascriptDirectory() as NSString).stringByAppendingPathComponent(fileName!)
        }
    }
    
    /// Get the default destination path for ".html" files in the project (owner) and adds the fileName at the end
    /// or the default name if fileName is nil
    ///
    /// - parameter fileName: name you want to give to the file
    /// - returns: the complete path
    func htmlFileDestination(fileName:String?) -> String? {
        if fileName == "" || fileName == nil {
            if let defaultFile = AutomatFileManager.htmlDefaultFile() {
                let defaultName = (defaultFile as NSString).lastPathComponent
                return (htmlDirectory() as NSString).stringByAppendingPathComponent(defaultName)
            } else {
                print("couldn't retrieve default name for html file")
                return nil
            }
        } else {
            return (htmlDirectory() as NSString).stringByAppendingPathComponent(fileName!)
        }
    }
    
    /// Get the default destination path for image files in the project (owner) and adds the fileName at the end
    /// or name it "unnamed image" if fileName is nil
    ///
    /// - parameter fileName: name you want to give to the image
    /// - returns: the complete path
    func imageFileDestination(fileName:String?) -> String? {
        var name = fileName
        if fileName == "" || fileName == nil {
            name = "unnamed image"
        }
        return (automatDirectory() as NSString).stringByAppendingPathComponent(name!)
    }
    
    // ==================================================================
    // MARK: * Default directories for files
    
    func automatDirectory() -> String {
        return (rootFolderPath as NSString).stringByAppendingPathComponent("automat")
    }
    func cssDirectory() -> String {
        return (rootFolderPath as NSString).stringByAppendingPathComponent("css")
    }
    func javascriptDirectory() -> String {
        return (rootFolderPath as NSString).stringByAppendingPathComponent("lib")
    }
    func htmlDirectory() -> String {
        return rootFolderPath
    }
    func imageDirectory() -> String {
        return (rootFolderPath as NSString).stringByAppendingPathComponent("images")
    }
    
    // ==================================================================
    // MARK: ************   Class functions (static)   ************
    // ==================================================================
    
    // ==================================================================
    // MARK: * File Creation
    
    class func createDirectoryAtPath(directoryPath:String) {
        if !NSFileManager.defaultManager().fileExistsAtPath(directoryPath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
    }
    
    class func createFileAtPath(destinationPath:String, fromFile sourcePath:String) -> Bool {
        var error:NSError?
        do {
            try NSFileManager.defaultManager().copyItemAtPath(sourcePath, toPath: destinationPath)
            // if we created an automat file, we need the html equivalent
            if (destinationPath as NSString).pathExtension == "automat" {
                if generateHtmlFromAutomatFileAtPath(destinationPath) {
                    // copy ok + HTML creation ok
                    return true
                } else {
                    // if we couldn't generate HTML file
                    return false
                }
            } else {
                // it wasn't an automat file, we're good
                return true
            }
        } catch let error1 as NSError {
            error = error1
            // if we couldn't copy the file at all
            if let actualError = error {
                print("\(self.className()): can't copy file - error: \(actualError)")
            }
            return false
        }
    }
    
    class func generateHtmlFromAutomatFileAtPath(path:String) -> Bool {
        // TODO: fill the function when AutomatParser is ready
        // convert automat file
        //let convertedAutomatFile:String? = "Automat converted to HTML" // <- need the AutomatParser function
        let convertedAutomatFile:String? = Parser.automatFileToHtml(path)
        if convertedAutomatFile == nil {
            return false
        }
        
        let htmlFilePath = getHtmlFileOfAutomatFileAtPath(path)
        if let actualHtmlFilePath = htmlFilePath {
            var error:NSError?
            do {
                try convertedAutomatFile!.writeToFile(actualHtmlFilePath, atomically: true, encoding: NSUTF8StringEncoding)
            } catch let error1 as NSError {
                error = error1
            }
            if let actualError = error {
                print("\(self.className()): error writing converted automat file: \(actualError)")
                return false
            }
        }
        
        return true
    }
    
    // ==================================================================
    // MARK: * File Deletion
    
    class func deleteFile(path:String) {
        // if we're trashing an automat file, trash its html file as well
        if (path as NSString).pathExtension == "automat" {
            let htmlFilePath = getHtmlFileOfAutomatFileAtPath(path)
            if let actualHtmlFilePath = htmlFilePath {
                let url = NSURL(fileURLWithPath: actualHtmlFilePath)
                do {
                    try NSFileManager.defaultManager().trashItemAtURL(url, resultingItemURL: nil)
                } catch let error as NSError {
                    print("\(self.className()): Error while deleting file: \(error)")
                }
            }
        }
        
        // if we're trashing an html file, trash its automat file as well if it exists
        if (path as NSString).pathExtension == "html" {
            let automatFilePath = getAutomatFileOfHtmlFileAtPath(path)
            if let actualAutomatFilePath = automatFilePath {
                if NSFileManager.defaultManager().fileExistsAtPath(actualAutomatFilePath) {
                    let url = NSURL(fileURLWithPath: actualAutomatFilePath)
                    do {
                        try NSFileManager.defaultManager().trashItemAtURL(url, resultingItemURL: nil)
                    } catch let error as NSError {
                        print("\(self.className()): Error while deleting file: \(error)")
                    }
                }
                // else there's no automat file for this html
            }
        }
        
        // then trash the file itself
        let url = NSURL(fileURLWithPath: path)
        do {
            try NSFileManager.defaultManager().trashItemAtURL(url, resultingItemURL: nil)
        } catch let error as NSError {
            print("\(self.className()): Error while deleting file: \(error)")
        }
    }
    
    // ==================================================================
    // MARK: * Getting file informations
    
    class func getFileInfos(path:String) -> [String:String] {
        var result:[String:String] = [String:String]()
        
        result["directory"] = (path as NSString).stringByDeletingLastPathComponent
        result["name"] = ((path as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
        result["extension"] = (path as NSString).pathExtension
        
        return result
    }
    
    class func getHtmlFileOfAutomatFileAtPath(path:String) -> String? {
        if ((path as NSString).pathExtension != "automat") {
            print("file at path \(path) is not an automat file")
            return nil
        }
        
        let infos:[String:String] = getFileInfos(path)
        let dir = infos["directory"]
        let fileName = infos["name"]
        if dir != nil && fileName != nil {
            let htmlDir = (dir! as NSString).stringByDeletingLastPathComponent
            let htmlFileName = (fileName! as NSString).stringByAppendingPathExtension("html")
            if let tempHtmlFileName = htmlFileName {
                return (htmlDir as NSString).stringByAppendingPathComponent(tempHtmlFileName)
            }
        }
        print("couldn't retrieve html file path of automat file at path \(path)")
        return nil
    }
    
    class func getAutomatFileOfHtmlFileAtPath(path:String) -> String? {
        if (path as NSString).pathExtension != "html" {
            print("file at path \(path) is not an html file")
            return nil
        }
        
        let infos:[String:String] = getFileInfos(path)
        let dir = infos["directory"]
        let fileName = infos["name"]
        if dir != nil && fileName != nil {
            let automatDir = (dir! as NSString).stringByAppendingPathComponent("automat")
            let automatFileName = (fileName! as NSString).stringByAppendingPathExtension("automat")
            if let actualAutomatFileName = automatFileName {
                return (automatDir as NSString).stringByAppendingPathComponent(actualAutomatFileName)
            }
        }
        print("couldn't retrieve automat file path of html file at path \(path)")
        return nil
    }
    
    // ==================================================================
    // MARK: * File Modification
    
    class func renameFile(filePath:String, to fileName:String) -> Bool {
        // when renaming we can't add path component, so avoid "/"
        let newName = fileName.stringByReplacingOccurrencesOfString("/", withString: "")
        
        // TODO: decide by usage if changing extension should be permitted
        // force keeping the same extension
        if (filePath as NSString).pathExtension != (newName as NSString).pathExtension {
            ((newName as NSString).stringByDeletingPathExtension as NSString).stringByAppendingPathExtension((filePath as NSString).pathExtension)
        }
        
        let newPath = ((filePath as NSString).stringByDeletingLastPathComponent as NSString).stringByAppendingPathComponent(newName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(newPath) {
            // TODO: show an alert?
            print("can't change name to an existing name")
            return false
        }
        
        // if it's an automat file, modify the corresponding html file as well
        if (newPath as NSString).pathExtension == "automat" {
            let htmlFilePath = getHtmlFileOfAutomatFileAtPath(filePath)
            let htmlNewFilePath = getHtmlFileOfAutomatFileAtPath(newPath)
            if htmlFilePath == nil || htmlNewFilePath == nil {
                print("couldn't retrieve html file path from automat file path")
                return false
            }
            
            if NSFileManager.defaultManager().fileExistsAtPath(htmlNewFilePath!) {
                // TODO: show an alert?
                print("an html with that name already exists")
                return false
            }
            
            // modifiy html name by moving the file
            var error:NSError?
            do {
                try NSFileManager.defaultManager().moveItemAtPath(htmlFilePath!, toPath: htmlNewFilePath!)
            } catch let error1 as NSError {
                error = error1
            }
            if let actualError = error {
                print("Error while moving file: \(actualError)")
                return false
            }
        }
        
        // if it's an html file, modify the corresponding automat file as well if it exists
        if (newPath as NSString).pathExtension == "html" {
            let automatFilePath = getAutomatFileOfHtmlFileAtPath(filePath)
            if let actualAutomatFilePath = automatFilePath {
                // only if the file exists
                if NSFileManager.defaultManager().fileExistsAtPath(actualAutomatFilePath) {
                    let automatNewFilePath = getAutomatFileOfHtmlFileAtPath(newPath)
                    if automatNewFilePath == nil {
                        print("couldn't retrieve automat file path from html new file path")
                        return false
                    }
                    if NSFileManager.defaultManager().fileExistsAtPath(automatNewFilePath!) {
                        // TODO: show an alert?
                        print("an automat file with that name already exists")
                        return false
                    }
                    
                    // modifiy automat name by moving the file
                    var error:NSError?
                    do {
                        try NSFileManager.defaultManager().moveItemAtPath(actualAutomatFilePath, toPath: automatNewFilePath!)
                    } catch let error1 as NSError {
                        error = error1
                    }
                    if let actualError = error {
                        print("Error while moving file: \(actualError)")
                        return false
                    }
                }
            }
        }
        
        // modifiy file name by moving the file
        var error:NSError?
        do {
            try NSFileManager.defaultManager().moveItemAtPath(filePath, toPath: newPath)
        } catch let error1 as NSError {
            error = error1
        }
        if let actualError = error {
            print("Error while moving file: \(actualError)")
            return false
        }
        
        return true
    }
    
    class func moveFile(filePath:String, to folderPath:String) -> Bool {
        if (filePath as NSString).stringByDeletingLastPathComponent == folderPath {
            print("don't need to move file in its own folder")
            return false
        }
        
        let newPath = (folderPath as NSString).stringByAppendingPathComponent((filePath as NSString).lastPathComponent)
        if NSFileManager.defaultManager().fileExistsAtPath(newPath) {
            // TODO: how to handle this? Give choice to cancel/overwrite/keep both?
            print("a file with same name already exists")
            return false
        }
        
        var error:NSError?
        do {
            try NSFileManager.defaultManager().moveItemAtPath(filePath, toPath: newPath)
        } catch let error1 as NSError {
            error = error1
        }
        if let actualError = error {
            print("Error while moving file: \(actualError)")
            return false
        }
        
        return true
    }
    
    // ==================================================================
    // MARK: * Utilities for managing files with same name
    
    class func suffixeOfNextFileForFile(path:String) -> String? {
        let fileInfos = getFileInfos(path)
        
        let dir = fileInfos["directory"]
        let fileName = fileInfos["name"]
        let ext = fileInfos["extension"]
        
        if dir != nil && fileName != nil && ext != nil {
            var suffixe = ""
            
            var index = 1
            while NSFileManager.defaultManager().fileExistsAtPath("\(dir!)/\(fileName!)\(suffixe).\(ext!)") {
                index++
                suffixe = "\(index)"
            }
            
            return suffixe
        } else {
            print("\(self.className()): couldn't find file infos from path: \(path)")
            return nil
        }
    }
    
    class func getValidDestinationPathForFile(path:String) -> String? {
        var suffixe:String?
        
        if (path as NSString).pathExtension == "automat" {
            // automat files generate html files. So we need to check if html pages exist instead of automat pages.
            let htmlFilePath = getHtmlFileOfAutomatFileAtPath(path)
            if let actualHtmlFilePath = htmlFilePath {
                suffixe = suffixeOfNextFileForFile(actualHtmlFilePath)
            }
        } else {
            suffixe = suffixeOfNextFileForFile(path)
        }
        
        // unwrap the suffixe and create the valid destination path
        if let actualSuffixe = suffixe {
            let ext = (path as NSString).pathExtension
            return ((path as NSString).stringByDeletingPathExtension.stringByAppendingString(actualSuffixe) as NSString).stringByAppendingPathExtension(ext)
        } else {
            print("\(self.className()): impossible to get a valid destination for file \(path)")
            return nil
        }
    }
    
    // ==================================================================
    // MARK: * Paths for default files
    
    class func automatDefaultFile() -> String? {
        return NSBundle.mainBundle().pathForResource("page", ofType: ".automat", inDirectory: "DefaultFiles")
    }
    class func cssDefaultFile() -> String? {
        return NSBundle.mainBundle().pathForResource("default", ofType: ".css", inDirectory: "DefaultFiles")
    }
    class func javascriptDefaultFile() -> String? {
        return NSBundle.mainBundle().pathForResource("script", ofType: ".js", inDirectory: "DefaultFiles")
    }
    class func htmlDefaultFile() -> String? {
        return NSBundle.mainBundle().pathForResource("page", ofType: ".html", inDirectory: "DefaultFiles")
    }
    
    // ==================================================================
    // MARK: * File Type Tests
    
    class func getFileUTI(path:String) -> CFString {
        let fileExtension:CFString = (path as NSString).pathExtension as NSString
        return UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)!.takeUnretainedValue()
    }
    
    class func fileAtPathIsAnImage(path:String) -> Bool {
        return UTTypeConformsTo(getFileUTI(path), kUTTypeImage)
    }
    
    class func fileAtPathIsAnAudiovisualContent(path:String) -> Bool {
        return UTTypeConformsTo(getFileUTI(path), kUTTypeAudiovisualContent)
    }
    
    class func fileAtPathIsATextFile(path:String) -> Bool {
        if (path as NSString).pathExtension == "automat" { return true }
        return UTTypeConformsTo(getFileUTI(path), kUTTypeText)
    }
    
}

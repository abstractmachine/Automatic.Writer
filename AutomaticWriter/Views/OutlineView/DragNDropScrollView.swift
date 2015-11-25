//
//  DragNDropScrollView.swift
//  AutomaticWriter
//
//  Created by Raphael on 26.01.15.
//  Copyright (c) 2015 HEAD Geneva. All rights reserved.
//

import Cocoa

protocol DragNDropScrollViewDelegate {
    func onFilesDrop(files:[String]);
}

class DragNDropScrollView: NSScrollView {

    var delegate:DragNDropScrollViewDelegate?
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    func registerForDragAndDrop(theDelegate:DragNDropScrollViewDelegate) {
        registerForDraggedTypes([NSColorPboardType, NSFilenamesPboardType])
        delegate = theDelegate
    }
    
    // the value returned changes the mouse icon
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        Swift.print("drag entered")
        
        let pboard:NSPasteboard = sender.draggingPasteboard()
        let sourceDragMask:NSDragOperation = sender.draggingSourceOperationMask()
        
        // cast the types array from [AnyObject]? to [String]
        let types:[String]? = pboard.types as [String]?
        
        if let actualTypes = types {
            if actualTypes.contains(NSFilenamesPboardType) {
                if (sourceDragMask.intersect(NSDragOperation.Link)) == NSDragOperation.Link {
                    // we get a link, but we're going to copy files
                    // so we show a "copy" icon
                    return NSDragOperation.Copy
                }
                else if (sourceDragMask.intersect(NSDragOperation.Copy)) == NSDragOperation.Copy {
                    return NSDragOperation.Copy
                }
            }
        }
        
        return NSDragOperation.None
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        Swift.print("perform drag operation")
        let pboard = sender.draggingPasteboard()
        let sourceDragMask = sender.draggingSourceOperationMask()
        
        // cast the types array from [AnyObject]? to [String]
        let types:[String]? = pboard.types as [String]?
        
        if let actualTypes = types {
            if actualTypes.contains(NSFilenamesPboardType) {
                let files: AnyObject? = pboard.propertyListForType(NSFilenamesPboardType)
                
                let paths = files as? [String]
                
                if (sourceDragMask.intersect(NSDragOperation.Link)) == NSDragOperation.Link {
                    if let actualPaths = paths {
                        Swift.print("files dropped: \(actualPaths)")
                        delegate?.onFilesDrop(actualPaths)
                    }
                }
            }
        }
        
        return true
    }
    
}

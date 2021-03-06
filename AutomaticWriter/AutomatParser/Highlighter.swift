//
//  Highlighter.swift
//  AutomaticWriter
//
//  Created by Raphael on 18.02.15.
//  Copyright (c) 2015 HEAD Geneva. All rights reserved.
//

import Cocoa

class Highlighter: NSObject {
    
    // MARK: * patterns for regular expressions
    struct RegexPattern {
        static let title = "(?:(?<=\\n)|(?<=\\A)):: (.+?)(?:(?=\\n)|(?=\\Z))"
                         // (?:(?<=\n)|(?<=\A)):: (.+?)(?:(?=\n)|(?=\Z))
        
        static let cssImports = "(?:(?<=\\n)|(?<=\\A))#import \"([^\"]+?.css)\" ?((?://)?.*?)?(?:(?=\\n)|(?=\\Z))"
                              // (?:(?<=\n)|(?<=\A))#import "([^"]+?.css)" ?((?://)?.*?)?(?:(?=\n)|(?=\Z))
        
        static let jsImports = "(?:(?<=\\n)|(?<=\\A))#import \"([^\"]+?.js)\" ?((?://)?.*?)?(?:(?=\\n)|(?=\\Z))"
                             // (?:(?<=\n)|(?<=\A))#import "([^"]+?.js)" ?((?://)?.*?)?(?:(?=\n)|(?=\Z))
        
        static let automatImports = "(?:(?<=\\n)|(?<=\\A))#import \"([^\"]+?.automat)\" ?((?://)?.*?)?(?:(?=\\n)|(?=\\Z))"
        
        static let jsVars = "(?:(?<=\\n)|(?<=\\A))(var \\w+? ?= ?[^;\\n]+?; ?(?://.*?)?)(?:(?=\\n)|(?=\\Z))"
                          // (?:(?<=\n)|(?<=\A))(var \w+? ?= ?[^;\n]+?; ?(?://.*?)?)(?:(?=\n)|(?=\Z))
        
        static let jsFunctions = "(?:(?<=\\n)|(?<=\\A))(var \\w+? ?= ?function ?\\(.*?\\) ?\\{ ?(?://.*?)?)(?:(?=\\n)|(?=\\Z))"
                               // (?:(?<=\n)|(?<=\A))(var \w+? ?= ?function ?\(.*?\) ?\{ ?(?://.*?)?)(?:(?=\n)|(?=\Z))
        
        
        static let jsFunctionCalls = "(?:(?<=\\n)|(?<=\\A))(\\w+\\([^\\)]*\\); ?(?://.*?)?)(?:(?=\\n)|(?=\\Z))"
                                   // (?:(?<=\n)|(?<=\A))(\w+\([^\)]+\); ?(?://.*?)?)(?:(?=\n)|(?=\Z))
        
        
        static let events = "(?:(?<=\\n)|(?<=\\A)) *([^\\n\\t\\{\\}\\\\\\/\\?!<]*?) *< *([\\w]+) *= *\"?([\\w]+) *(?:\\(([\\w, ]*)\\))?\"? *>[ \\t]*(?://(.*?))?(?:(?=\\n)|(?=\\Z))"
                          // (?:(?<=^)) *([^\n\t\{\}\\\/\?!<]*?) *< *([\w]+) *= *"?([\w]+) *(?:\(([\w, ]*)\))?"? *>[ \t]*(?://(.*?))?(?:(?=\n)|(?=\Z))
        
        static let twine = "\\[\\[([^\\n\\[\\]|]+)\\|?([^\\n\\[\\]|]+)?\\]\\[?([^\\]]+)?\\]?\\]"
                         // \[\[(\w+)\|?(\w+)?\]\[?([^\]]+)?\]?\]
                         // \[\[([^\n\[\]|]+)\|?([^\n\[\]|]+)?\]\[?([^\]]+)?\]?\]
        
        static let commentLines = "(?:(?<=\\n)|(?<=\\A))//([^\\n]*)"
                                // (?:(?<=\n)|(?<=\A))//([^\n]*)
        static let comments = "(?:(?<=\\n)|(?<=\\A))[ \\t]*?// *?([^\\n]*)"
                           // " *?// *?([^\n]*)"
                           // "(?:(?<=\n)|(?<=\A))[ \t]*?// *?([^\n]*)"
        
        static let blockOpeningTags = "(?:(?<=\\n)|(?<=\\A))([#\\.])([^.# ]+[^\\{])\\{{2}"
                                   // (?:(?<=\n)|(?<=\A))([#\.])([^.# ]+)\{\{
                                   // (?:(?<=\n)|(?<=\A))([#\.])([^.# ]+[^\{])\{{2}
        
        static let inlineOpeningTags = "(?<=[^\\n])([#\\.])([^.# ]+[^\\{])\\{{2}"
                                    // (?<= )([#\.])([^.# ]+)\{\{
                                    // (?<= )([#\.])([^.# ]+[^\{])\{{2}
                                    // (?<=[^\n])([#\.])([^.# ]+[^\{])\{{2}
        
        static let blockClosingTags = "\\}{2}(?:<(.*?)>)?(?:(?=\\n)|(?=\\Z))"
                                    // \}{2}(?:<(.*?)>)?(?:(?=\n)|(?=\Z))
        
        static let inlineClosingTags = "(?<!\\n)\\}{2}(?:<([^>\\n]+?)>)?[:punct:]*?(?!(\\Z|\\n))"
                                     // (?<!\n)\}{2}(?:<([^>\n]+?)>)?[:punct:]*?(?!(\Z|\n))
    }
    
    // MARK: * Utility functions
    func rangeIsValid(range:NSRange) -> Bool {
        return !NSEqualRanges(range, NSMakeRange(NSNotFound, 0))
    }
    
    // MARK: * Regex handling
    func initRegex(pattern:String, options:NSRegularExpressionOptions) -> NSRegularExpression? {
        //var error:NSError?
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: pattern, options: options)
            return regex
        } catch let error as NSError {
            regex = nil
            print("\(self.className) - error while trying to find regex \"\(pattern)\" in string, error: \(error)")
            return nil
        }
    }
    
    func getFirstTokenForPattern(pattern:String, ofType type:HighlightType, inRange range:NSRange, forText text:String) -> HighlightToken? {
        if let regex = initRegex(pattern, options: NSRegularExpressionOptions.CaseInsensitive) {
            if let match = regex.firstMatchInString(text, options: NSMatchingOptions.ReportProgress, range: range) {
                var ranges:[NSRange] = [NSRange]()
                for var i = 0; i < match.numberOfRanges; ++i {
                    ranges += [match.rangeAtIndex(i)]
                }
                return HighlightToken(_ranges: ranges, _type: type)
            }
        }
        return nil  // pattern not found in range
    }
    
    func getTokensForPattern(pattern:String, ofType type:HighlightType, inRange range:NSRange, forText text:String) -> [HighlightToken] {
        var tokens = [HighlightToken]()
        if let regex = initRegex(pattern, options: NSRegularExpressionOptions.CaseInsensitive) {
            let matches = regex.matchesInString(text, options: NSMatchingOptions.ReportProgress, range: range)
            for result in matches {
                let match = result 
                var ranges:[NSRange] = [NSRange]()
                for var i = 0; i < match.numberOfRanges; ++i {
                    ranges += [match.rangeAtIndex(i)]
                }
                tokens += [HighlightToken(_ranges: ranges, _type: type)]
            }
        }
        return tokens
    }
    
    func findAutomatImportsInRange(range:NSRange, forText text:String) -> [HighlightToken] {
        var highlights = [HighlightToken]()
        highlights += getTokensForPattern(RegexPattern.automatImports, ofType: HighlightType.AUTOMATIMPORT, inRange: range, forText: text)
        
        return highlights
    }
    
    // MARK: * Highlights search
    func findHighlightsInRange(range:NSRange, forText text:String) -> [HighlightToken] {
        //fullText = text
        var highlights = [HighlightToken]()
        
        if let titleToken = getFirstTokenForPattern(RegexPattern.title, ofType: HighlightType.TITLE, inRange: range, forText: text) {
            highlights += [titleToken]
        }
        highlights += getTokensForPattern(RegexPattern.automatImports, ofType: HighlightType.AUTOMATIMPORT, inRange: range, forText: text)
        highlights += getTokensForPattern(RegexPattern.cssImports, ofType: HighlightType.CSSIMPORT, inRange: range, forText: text)
        highlights += getTokensForPattern(RegexPattern.jsImports, ofType: HighlightType.JSIMPORT, inRange: range, forText: text)
        highlights += getTokensForPattern(RegexPattern.jsVars, ofType: HighlightType.JSDECLARATION, inRange: range, forText: text)
        highlights += findJsFunctions(range, inText: text)
        highlights += getTokensForPattern(RegexPattern.jsFunctionCalls, ofType: HighlightType.JS, inRange: range, forText: text)
        highlights += getTokensForPattern(RegexPattern.events, ofType: HighlightType.EVENT, inRange: range, forText: text)
        highlights += getTokensForPattern(RegexPattern.twine, ofType: HighlightType.TWINE, inRange: range, forText: text)
        highlights += findTags(range, inText: text)
        highlights += getTokensForPattern(RegexPattern.comments, ofType: HighlightType.COMMENT, inRange: range, forText: text) // end with comments to override color
        
        //let start = NSDate()
        //let end = NSDate()
        //let timeInterval:Double = end.timeIntervalSinceDate(start)
        //println("highlights found in \(timeInterval*1000) milliseconds")
        
        return highlights
    }
    
    func findJsFunctions(range:NSRange, inText text:String) -> [HighlightToken] {
        var tokens = [HighlightToken]()
        
        // first we need the beginning of the function
        let funcOpenings = getTokensForPattern(RegexPattern.jsFunctions, ofType: HighlightType.JSDECLARATION, inRange: range, forText: text)
        let textLength = text.characters.count
        
        // then we must find the closing part for each function
        for opening in funcOpenings {
            // search begin at the end of the opening match
            let newRangeLocation = opening.ranges[0].location+opening.ranges[0].length
            let newRange = NSMakeRange(newRangeLocation, textLength - newRangeLocation)
            
            // use pattern \{|\} to find opening or closing braces
            if let regex = initRegex("\\{|\\}", options: NSRegularExpressionOptions.CaseInsensitive) {
                var nestedLevel = 0
                // enumerate results and stop when we find what we need
                regex.enumerateMatchesInString(text, options: NSMatchingOptions.ReportProgress, range: newRange) {
                    match, flags, stop in
                    if let actualMatch = match {
                        if text[text.startIndex.advancedBy(actualMatch.range.location)] == "{" {
                            nestedLevel++
                        } else {
                            if nestedLevel > 0 {
                                nestedLevel--
                            } else {
                                // we found the closing curly brace
                                var ranges:[NSRange] = [NSRange]()
                                let fullRangeLength = (actualMatch.range.location + actualMatch.range.length) - opening.ranges[0].location
                                ranges += [NSMakeRange(opening.ranges[0].location, fullRangeLength)]    // full range
                                ranges += opening.ranges                                                // ranges of opening token
                                ranges += [actualMatch.range]                                                 // range of closing curly brace
                                
                                tokens += [HighlightToken(_ranges: ranges, _type: HighlightType.JSDECLARATION)]
                                stop.memory = true
                            }
                        }
                    }
                }
            }
        }
        return tokens
    }
    
    func findTags(range:NSRange, inText text:String) -> [HighlightToken] {
        var tokens = [HighlightToken]()
        
        tokens += getTokensForPattern(RegexPattern.blockOpeningTags, ofType: HighlightType.OPENINGBLOCKTAG, inRange: range, forText: text)
        tokens += getTokensForPattern(RegexPattern.inlineOpeningTags, ofType: HighlightType.OPENINGINLINETAG, inRange: range, forText: text)
        tokens += getTokensForPattern(RegexPattern.blockClosingTags, ofType: HighlightType.CLOSINGBLOCKTAG, inRange: range, forText: text)
        tokens += getTokensForPattern(RegexPattern.inlineClosingTags, ofType: HighlightType.CLOSINGINLINETAG, inRange: range, forText: text)
        
        tokens.sortInPlace({$0.ranges[0].location < $1.ranges[0].location})
        
        var pairs = [Pair]()
        
        while(tokens.count > 1) {
            // remove closing tags that could be leading the array
            while tokenIsAClosingTag(tokens[0]) {
                //println("remove token \(tokens[0])")
                tokens.removeAtIndex(0)
                if tokens.count == 0 { break; }
            }
            if tokens.count < 2 { break; } // can't find pairs with less than 2 elements
            
            var openingTagIndex = -1
            var nestLevel = 0
            var tokensToRemove = [Int]()
            
            for (index, token) in tokens.enumerate() {
                if openingTagIndex == -1 {  // we're looking for a tag opening
                    if (!tokenIsAClosingTag(token)) {
                        openingTagIndex = index // that's the opening token
                        nestLevel = 0
                        continue
                    } else {
                        continue
                    }
                }
                
                if tokenIsAClosingTag(token) {
                    if nestLevel > 0 {
                        nestLevel--
                    } else {
                        // pair ok
                        pairs += [Pair(_a: tokens[openingTagIndex], _b: token)]
                        tokensToRemove.insert(openingTagIndex, atIndex: 0) // insert inverted
                        
                        // reset index for next tag
                        nestLevel = 0
                        openingTagIndex = -1
                    }
                } else {
                    nestLevel++
                }
            }
            if tokensToRemove.isEmpty && openingTagIndex > -1 {
                tokens.removeAtIndex(openingTagIndex)
            }
            for removeIndex in tokensToRemove {
                tokens.removeAtIndex(removeIndex)
            }
        }
        
        // insert back pairs into tokens
        tokens.removeAll(keepCapacity: false)
        for pair in pairs {
            let a:HighlightToken = pair.a as! HighlightToken
            let b:HighlightToken = pair.b as! HighlightToken
            tokens += [a, b]
            //println([a, b])
        }
        
        return tokens
    }
    
    func tokenIsAClosingTag(token:HighlightToken) -> Bool {
        return token.type == HighlightType.CLOSINGBLOCKTAG || token.type == HighlightType.CLOSINGINLINETAG
    }
    
}

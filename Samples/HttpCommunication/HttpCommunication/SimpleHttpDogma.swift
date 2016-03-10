//
//  HttpDogma.swift
//  HttpCommunication
//
//  Created by Tae Hyun Na on 2016. 3. 7.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import Foundation

class SimpleHttpDogma : HJAsyncTcpCommunicateDogma
{
    override func methodType() -> HJAsyncTcpCommunicateDogmaMethodType {
        
        return HJAsyncTcpCommunicateDogmaMethodTypeHeaderWithBody
    }
    
    override func lengthOfHeaderFromStream(stream:UnsafeMutablePointer<UInt8>, streamLength:UInt, appendedLength:UInt) -> UInt {
        
        if let string = NSString(bytes:stream, length:Int(streamLength), encoding:NSUTF8StringEncoding) {
            let range = string.rangeOfString("\r\n\r\n")
            if range.location == NSNotFound {
                return 0
            }
            return UInt(range.location+range.length)
        }
        
        return 0
    }
    
    override func headerObjectFromHeaderStream(stream:UnsafeMutablePointer<UInt8>, streamLength:UInt) -> AnyObject! {
        
        return NSString(bytes:stream, length:Int(streamLength), encoding:NSUTF8StringEncoding)
    }
    
    override func isBrokenHeaderObject(headerObject:AnyObject!) -> Bool {
        
        if headerObject == nil {
            return true
        }
        
        return false
    }
    
    override func lengthOfBodyFromHeaderObject(headerObject:AnyObject!) -> UInt {
        
        let headerString:NSString = headerObject as! NSString
        let beginRange = headerString.rangeOfString("Content-Length: ")
        if beginRange.location == NSNotFound {
            return 0
        }
        let beginIndex = beginRange.location + beginRange.length
        let endRange = headerString.rangeOfString("\r\n", options: NSStringCompareOptions.CaseInsensitiveSearch, range:NSMakeRange(beginIndex, headerString.length-beginIndex))
        if endRange.location == NSNotFound {
            return 0
        }
        let contentLengthString = headerString.substringWithRange(NSMakeRange(beginIndex, endRange.location-beginIndex))
        
        return UInt(contentLengthString)!
    }
    
    override func bodyObjectFromBodyStream(stream:UnsafeMutablePointer<UInt8>, streamLength:UInt, headerObject:AnyObject!) -> AnyObject! {
        
        return NSString(bytes:stream, length:Int(streamLength), encoding:NSUTF8StringEncoding)
    }
    
    override func isBrokenBodyObject(bodyObject: AnyObject!) -> Bool {
        
        if bodyObject == nil {
            return true
        }
        
        return false
    }
    
    override func lengthOfHeaderFromHeaderObject(headerObject:AnyObject!) -> UInt {
        
        let headerString = headerObject as! NSString
        
        return UInt(headerString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    }
    
    override func lengthOfBodyFromBodyObject(bodyObject:AnyObject!) -> UInt {
        
        if bodyObject == nil {
            return 0
        }
        let bodyString = bodyObject as! NSString
        
        return UInt(bodyString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    }
    
    override func writeBuffer(writeBuffer:UnsafeMutablePointer<UInt8>, bufferLength:UInt, fromHeaderObject headerObject:AnyObject!, bodyObject:AnyObject!) -> UInt {
        
        if (writeBuffer == nil) || (bufferLength == 0) {
            return 0
        }
        var headerLength:UInt! = 0
        if let _ = headerObject {
            headerLength = self.lengthOfHeaderFromHeaderObject(headerObject)
        }
        var bodyLength:UInt! = 0
        if let _ = bodyObject {
            bodyLength = self.lengthOfBodyFromBodyObject(bodyObject)
        }
        let amountLength = headerLength + bodyLength
        if (amountLength == 0) || (amountLength > bufferLength) {
            return 0
        }
        
        let plook:UnsafeMutablePointer<UInt8> = writeBuffer
        if headerLength > 0 {
            let headerString = headerObject as! NSString
            memcpy(plook, headerString.UTF8String, Int(headerLength))
            plook.memory += UInt8(headerLength)
        }
        if bodyLength > 0 {
            let bodyString = bodyObject as! NSString
            memcpy(plook, bodyString.UTF8String, Int(bodyLength))
        }
        
        return amountLength;
    }
}

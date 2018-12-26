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
        
        return .headerWithBody
    }
    
    override func lengthOfHeader(fromStream stream:UnsafeMutablePointer<UInt8>?, streamLength:UInt, appendedLength:UInt) -> UInt {
        
        guard let stream = stream else {
            return 0
        }
        if let string = NSString(bytes:stream, length:Int(streamLength), encoding:String.Encoding.utf8.rawValue) {
            let range = string.range(of: "\r\n\r\n")
            if range.location == NSNotFound {
                return 0
            }
            return UInt(range.location+range.length)
        }
        return 0
    }
    
    override func headerObject(fromHeaderStream stream:UnsafeMutablePointer<UInt8>?, streamLength:UInt) -> Any? {
        
        guard let stream = stream else {
            return nil
        }
        return NSString(bytes:stream, length:Int(streamLength), encoding:String.Encoding.utf8.rawValue)
    }
    
    override func isBrokenHeaderObject(_ headerObject:Any?) -> Bool {
        
        if headerObject == nil {
            return true
        }
        return false
    }
    
    override func lengthOfBody(fromHeaderObject headerObject:Any?) -> UInt {
        
        guard let headerString = headerObject as? NSString else {
            return 0
        }
        let beginRange = headerString.range(of: "Content-Length: ")
        if beginRange.location == NSNotFound {
            return 0
        }
        let beginIndex = beginRange.location + beginRange.length
        let endRange = headerString.range(of: "\r\n", options: NSString.CompareOptions.caseInsensitive, range:NSMakeRange(beginIndex, headerString.length-beginIndex))
        if endRange.location == NSNotFound {
            return 0
        }
        let contentLengthString = headerString.substring(with: NSMakeRange(beginIndex, endRange.location-beginIndex))
        return UInt(contentLengthString)!
    }
    
    override func bodyObject(fromBodyStream stream:UnsafeMutablePointer<UInt8>?, streamLength:UInt, headerObject:Any?) -> Any? {
        
        guard let stream = stream else {
            return nil
        }
        return NSString(bytes:stream, length:Int(streamLength), encoding:String.Encoding.utf8.rawValue)
    }
    
    override func isBrokenBodyObject(_ bodyObject: Any?) -> Bool {
        
        if bodyObject == nil {
            return true
        }
        return false
    }
    
    override func lengthOfHeader(fromHeaderObject headerObject:Any?) -> UInt {
        
        guard let headerString = headerObject as? NSString else {
            return 0
        }
        return UInt(headerString.lengthOfBytes(using: String.Encoding.utf8.rawValue))
    }
    
    override func lengthOfBody(fromBodyObject bodyObject:Any?) -> UInt {
        
        guard let bodyString = bodyObject as? NSString else {
            return 0
        }
        return UInt(bodyString.lengthOfBytes(using: String.Encoding.utf8.rawValue))
    }
    
    override func writeBuffer(_ writeBuffer: UnsafeMutablePointer<UInt8>?, bufferLength: UInt, fromHeaderObject headerObject: Any?, bodyObject: Any?, fragmentHandler: Any?) -> UInt {
        
        guard let writeBuffer = writeBuffer, bufferLength > 0 else {
            return 0;
        }
        let headerLength:UInt = (headerObject != nil) ? lengthOfHeader(fromHeaderObject: headerObject!) : 0
        let bodyLength:UInt! = (bodyObject != nil) ? lengthOfBody(fromBodyObject: bodyObject!) : 0
        let amountLength = headerLength + bodyLength
        if (amountLength <= 0) || (amountLength > bufferLength) {
            return 0
        }
        let plook:UnsafeMutablePointer<UInt8> = writeBuffer
        if let headerString = headerObject as? NSString, headerLength > 0 {
            memcpy(plook, headerString.utf8String, Int(headerLength))
            plook.pointee += UInt8(headerLength)
        }
        if let bodyString = bodyObject as? NSString, bodyLength > 0 {
            memcpy(plook, bodyString.utf8String, Int(bodyLength))
        }
        return amountLength;
    }
}

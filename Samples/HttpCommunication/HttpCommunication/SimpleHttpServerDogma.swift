//
//  SimpleHttpServerDogma.swift
//  
//
//  Created by Tae Hyun Na on 2019. 2. 13.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import Foundation

class SimpleHttpServerDogma : HJAsyncTcpCommunicateDogma
{
    override func supportMode() -> HJAsyncTcpCommunicateDogmaSupportMode {
        
        return .server
    }
    
    override func methodType() -> HJAsyncTcpCommunicateDogmaMethodType {
        
        return .bodyWithEof
    }
    
    override func lengthOfBody(fromStream stream: UnsafeMutablePointer<UInt8>?, streamLength: UInt, appendedLength: UInt) -> UInt {
        
        guard let stream = stream, let string = NSString(bytes:stream, length:Int(streamLength), encoding:String.Encoding.utf8.rawValue) else {
            return 0
        }
        let range = string.range(of: "\r\n\r\n")
        if range.location == NSNotFound {
            return 0
        }
        return UInt(range.location+range.length)
    }
    
    override func bodyObject(fromBodyStream stream:UnsafeMutablePointer<UInt8>?, streamLength:UInt, headerObject:Any?) -> Any? {
        
        guard let stream = stream, let string = NSString(bytes:stream, length:Int(streamLength), encoding:String.Encoding.utf8.rawValue) else {
            return 0
        }
        let range = string.range(of: "\r\n\r\n")
        if range.location == NSNotFound {
            return nil
        }
        return NSString(bytes:stream, length:Int(range.location+range.length), encoding:String.Encoding.utf8.rawValue)
    }
    
    override func isBrokenBodyObject(_ bodyObject: Any?) -> Bool {
        
        guard (bodyObject as? NSString) != nil else {
            return true
        }
        return false
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
        let bodyLength:UInt = (bodyObject != nil) ? lengthOfBody(fromBodyObject: bodyObject) : 0
        if (bodyLength <= 0) || (bodyLength > bufferLength) {
            return 0
        }
        let plook:UnsafeMutablePointer<UInt8> = writeBuffer
        if let bodyString = bodyObject as? NSString, bodyLength > 0 {
            memcpy(plook, bodyString.utf8String, Int(bodyLength))
        }
        return bodyLength;
    }
}

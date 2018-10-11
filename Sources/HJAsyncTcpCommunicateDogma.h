//
//  HJAsyncTcpCommunicateDogma.h
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import Foundation;

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateDogmaMethodType)
{
    HJAsyncTcpCommunicateDogmaMethodTypeStream,
    HJAsyncTcpCommunicateDogmaMethodTypeBodyWithEof,
    HJAsyncTcpCommunicateDogmaMethodTypeHeaderWithBody
    
};

@interface HJAsyncTcpCommunicateDogma : NSObject

- (HJAsyncTcpCommunicateDogmaMethodType)methodType;

- (NSUInteger)lengthOfHeaderFromStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength;
- (id _Nullable)headerObjectFromHeaderStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength;
- (BOOL)isBrokenHeaderObject:(id _Nullable)headerObject;

- (NSUInteger)lengthOfBodyFromStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength;
- (NSUInteger)lengthOfBodyFromHeaderObject:(id _Nullable)headerObject;
- (id _Nullable)bodyObjectFromBodyStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength headerObject:(id _Nullable)headerObject;
- (BOOL)isBrokenBodyObject:(id _Nullable)bodyObject;

- (NSUInteger)lengthOfHeaderFromHeaderObject:(id _Nullable)headerObject;
- (NSUInteger)lengthOfBodyFromBodyObject:(id _Nullable)bodyObject;
- (NSUInteger)writeBuffer:(unsigned char * _Nullable)writeBuffer bufferLength:(NSUInteger)bufferLength fromHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject;

@end

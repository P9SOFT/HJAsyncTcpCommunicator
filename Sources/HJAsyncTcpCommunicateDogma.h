//
//  HJAsyncTcpCommunicateDogma.h
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import Foundation;

typedef enum _HJAsyncTcpCommunicateDogmaMethodType_
{
    HJAsyncTcpCommunicateDogmaMethodTypeStream,
    HJAsyncTcpCommunicateDogmaMethodTypeBodyWithEof,
    HJAsyncTcpCommunicateDogmaMethodTypeHeaderWithBody
    
} HJAsyncTcpCommunicateDogmaMethodType;

@interface HJAsyncTcpCommunicateDogma : NSObject

- (HJAsyncTcpCommunicateDogmaMethodType)methodType;

- (NSUInteger)lengthOfHeaderFromStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength;
- (id)headerObjectFromHeaderStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength;
- (BOOL)isBrokenHeaderObject:(id)headerObject;

- (NSUInteger)lengthOfBodyFromStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength;
- (NSUInteger)lengthOfBodyFromHeaderObject:(id)headerObject;
- (id)bodyObjectFromBodyStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength headerObject:(id)headerObject;
- (BOOL)isBrokenBodyObject:(id)bodyObject;

- (NSUInteger)lengthOfHeaderFromHeaderObject:(id)headerObject;
- (NSUInteger)lengthOfBodyFromBodyObject:(id)bodyObject;
- (NSUInteger)writeBuffer:(unsigned char *)writeBuffer bufferLength:(NSUInteger)bufferLength fromHeaderObject:(id)headerObject bodyObject:(id)bodyObject;

@end

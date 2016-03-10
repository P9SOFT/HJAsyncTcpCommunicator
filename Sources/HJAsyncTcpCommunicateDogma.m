//
//  HJAsyncTcpCommunicateDogma.m
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJAsyncTcpCommunicateDogma.h"

@implementation HJAsyncTcpCommunicateDogma

- (HJAsyncTcpCommunicateDogmaMethodType)methodType
{
    return HJAsyncTcpCommunicateDogmaMethodTypeStream;
}

- (NSUInteger)lengthOfHeaderFromStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength
{
    return 0;
}

- (id)headerObjectFromHeaderStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength
{
    return nil;
}

- (BOOL)isBrokenHeaderObject:(id)headerObject
{
    if( [headerObject isKindOfClass:[NSData class]] == NO ) {
        return YES;
    }
    
    return NO;
}

- (NSUInteger)lengthOfBodyFromStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength
{
    return streamLength;
}

- (NSUInteger)lengthOfBodyFromHeaderObject:(id)headerObject
{
    return 0;
}

- (id)bodyObjectFromBodyStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength headerObject:(id)headerObject
{
    if( (stream == NULL) || (streamLength <= 0) ) {
        return nil;
    }
    
    return [NSData dataWithBytes:stream length:streamLength];
}

- (BOOL)isBrokenBodyObject:(id)bodyObject
{
    if( [bodyObject isKindOfClass:[NSData class]] == NO ) {
        return YES;
    }
    
    return NO;
}

- (NSUInteger)lengthOfHeaderFromHeaderObject:(id)headerObject
{
    if( [headerObject isKindOfClass:[NSData class]] == NO ) {
        return 0;
    }
    
    return [headerObject lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

- (NSUInteger)lengthOfBodyFromBodyObject:(id)bodyObject
{
    if( [bodyObject isKindOfClass:[NSData class]] == NO ) {
        return 0;
    }
    
    return [bodyObject lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

- (NSUInteger)writeBuffer:(unsigned char *)writeBuffer bufferLength:(NSUInteger)bufferLength fromHeaderObject:(id)headerObject bodyObject:(id)bodyObject
{
    if( (writeBuffer == NULL) || (bufferLength == 0) || ([headerObject isKindOfClass:[NSData class]] == NO) || ([bodyObject isKindOfClass:[NSData class]] == NO) ) {
        return 0;
    }
    
    NSUInteger headerLength = [self lengthOfHeaderFromHeaderObject:headerObject];
    NSUInteger bodyLength = [self lengthOfBodyFromBodyObject:bodyObject];
    NSUInteger amountLength = headerLength + bodyLength;
    if( (amountLength == 0) || (amountLength > bufferLength) ) {
        return 0;
    }
    
    unsigned char *plook = writeBuffer;
    if( headerLength > 0 ) {
        memcpy(plook, (unsigned char *)[headerObject bytes], headerLength);
        plook += headerLength;
    }
    if( bodyLength > 0 ) {
        memcpy(plook, (unsigned char *)[bodyObject bytes], bodyLength);
    }
    
    return amountLength;
}

@end

//
//  HJAsyncTcpCommunicateDogma.m
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJAsyncTcpCommunicateDogma.h"

@implementation HJAsyncTcpCommunicateWriteFragment

- (instancetype)initWithBufferSize:(NSInteger)size
{
    if( [super init] == nil ) {
        return nil;
    }
    if( [self prepareBufferForSize:size] == NO ) {
        return nil;
    }
    return self;
}

- (BOOL)prepareBufferForSize:(NSInteger)size
{
    if( size <= 0 ) {
        return NO;
    }
    if( _fragmentBuffer != NULL ) {
        _fragmentBuffer = (unsigned char *)realloc(_fragmentBuffer, (size_t)size);
    } else {
        _fragmentBuffer = (unsigned char *)malloc((size_t)size);
    }
    if( _fragmentBuffer != NULL ) {
        _fragmentLength = size;
    }
    return YES;
}

- (void)dealloc
{
    if( _fragmentBuffer != NULL ) {
        free(_fragmentBuffer);
        _fragmentBuffer = NULL;
        _fragmentLength = 0;
    }
}

@end

@implementation HJAsyncTcpCommunicateDogma

- (HJAsyncTcpCommunicateDogmaMethodType)methodType
{
    return HJAsyncTcpCommunicateDogmaMethodTypeStream;
}

- (BOOL)needHandshake:(id)anQuery
{
    return NO;
}

- (id)firstHandshakeObjectAfterConnected:(id)anQuery
{
    return nil;
}

- (id)nextHandshakeObjectAfterUpdateHandshakeStatusFromObject:(id)handshakeObject
{
    return nil;
}

- (NSUInteger)lengthOfHandshakeFromStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength
{
    return 0;
}

- (id)handshakeObjectFromHeaderStream:(unsigned char *)stream streamLength:(NSUInteger)streamLength
{
    return nil;
}

- (BOOL)isBrokenHandshakeObject:(id)handshakeObject
{
    return NO;
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

- (BOOL)isControlHeaderObject:(id _Nullable)headerObject
{
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

- (NSUInteger)lengthOfHandshakeFromHandshakeObject:(id)handshakeObject
{
    return 0;
}

- (id _Nullable)controlHeaderObjectHandling:(id _Nullable)headerObject
{
    return nil;
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

- (BOOL)writeAtOnce
{
    return YES;
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
    }
    if( bodyLength > 0 ) {
        if( headerLength > 0 ) {
            plook += headerLength;
        }
        memcpy(plook, (unsigned char *)[bodyObject bytes], bodyLength);
    }
    return amountLength;
}

- (NSArray<HJAsyncTcpCommunicateWriteFragment *> *)writeFragmentFromHeaderObject:(id)headerObject bodyObject:(id)bodyObject
{
    return nil;
}

- (BOOL)prepareAfterConnected
{
    return YES;
}

- (void)resetAfterDisconnected
{
}

@end

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

- (HJAsyncTcpCommunicateDogmaSupportMode)supportMode
{
    return HJAsyncTcpCommunicateDogmaSupportModeClientAndServer;
}

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

- (void)updateHandshkeStatusIfNeedAfterSent:(id)headerObject
{
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

- (BOOL)isBrokenControlObject:(id _Nullable)controlObject
{
    return YES;
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
    return [bodyObject length];
}

- (id _Nullable)fragmentHandlerFromHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject
{
    return nil;
}

- (NSUInteger)writeBuffer:(unsigned char * _Nullable)writeBuffer bufferLength:(NSUInteger)bufferLength fromHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject fragmentHandler:(id _Nullable)fragmentHandler
{
    if( (writeBuffer == NULL) || (bufferLength == 0) ) {
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

- (BOOL)clientAcceptedForKey:(NSString *)clientKey fromServerKey:(NSString *)serverKey
{
    return YES;
}

- (BOOL)prepareAfterConnected
{
    return YES;
}

- (BOOL)prepareAfterBinded
{
    return YES;
}

- (void)resetAfterDisconnected
{
}

- (void)resetAfterShutdowned
{
}

@end

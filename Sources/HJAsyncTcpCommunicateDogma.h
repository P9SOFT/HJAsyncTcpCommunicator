//
//  HJAsyncTcpCommunicateDogma.h
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import Foundation;

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateDogmaSupportMode)
{
    HJAsyncTcpCommunicateDogmaSupportModeClient,
    HJAsyncTcpCommunicateDogmaSupportModeServer,
    HJAsyncTcpCommunicateDogmaSupportModeClientAndServer
};

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateDogmaMethodType)
{
    HJAsyncTcpCommunicateDogmaMethodTypeStream,
    HJAsyncTcpCommunicateDogmaMethodTypeBodyWithEof,
    HJAsyncTcpCommunicateDogmaMethodTypeHeaderWithBody
    
};

typedef void(^HJAsyncTcpCommunicatorHandler)(BOOL, NSString * _Nullable, id _Nullable , id _Nullable);

@protocol HJAsyncTcpCommunicateFragmentHandlerProtocol

- (BOOL)haveWritableFragment;
- (NSUInteger)reserveFragment;
- (void)flushFragment;

@end

@interface HJAsyncTcpCommunicateDogma : NSObject

- (HJAsyncTcpCommunicateDogmaSupportMode)supportMode;
- (HJAsyncTcpCommunicateDogmaMethodType)methodType;

- (BOOL)needHandshake:(id _Nullable)anQuery;
- (id _Nullable)firstHandshakeObjectAfterConnected:(id _Nullable)anQuery;
- (id _Nullable)nextHandshakeObjectAfterUpdateHandshakeStatusFromObject:(id _Nullable)handshakeObject;
- (void)updateHandshkeStatusIfNeedAfterSent:(id _Nullable)headerObject;
- (NSUInteger)lengthOfHandshakeFromStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength;
- (id _Nullable)handshakeObjectFromHeaderStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength;
- (BOOL)isBrokenHandshakeObject:(id _Nullable)handshakeObject;

- (NSUInteger)lengthOfHeaderFromStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength;
- (id _Nullable)headerObjectFromHeaderStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength;
- (BOOL)isBrokenHeaderObject:(id _Nullable)headerObject;
- (BOOL)isControlHeaderObject:(id _Nullable)headerObject;
- (id _Nullable)controlHeaderObjectHandling:(id _Nullable)headerObject;
- (BOOL)isBrokenControlObject:(id _Nullable)controlObject;

- (NSUInteger)lengthOfBodyFromStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength appendedLength:(NSUInteger)appendedLength;
- (NSUInteger)lengthOfBodyFromHeaderObject:(id _Nullable)headerObject;
- (id _Nullable)bodyObjectFromBodyStream:(unsigned char * _Nullable)stream streamLength:(NSUInteger)streamLength headerObject:(id _Nullable)headerObject;
- (BOOL)isBrokenBodyObject:(id _Nullable)bodyObject;

- (NSUInteger)lengthOfHandshakeFromHandshakeObject:(id _Nullable)handshakeObject;
- (NSUInteger)lengthOfHeaderFromHeaderObject:(id _Nullable)headerObject;
- (NSUInteger)lengthOfBodyFromBodyObject:(id _Nullable)bodyObject;
- (id _Nullable)fragmentHandlerFromHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject;
- (NSUInteger)writeBuffer:(unsigned char * _Nullable)writeBuffer bufferLength:(NSUInteger)bufferLength fromHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject fragmentHandler:(id _Nullable)fragmentHandler;

- (BOOL)clientAcceptedForKey:(NSString * _Nullable)clientKey fromServerKey:(NSString * _Nullable)serverKey;

- (BOOL)prepareAfterConnected;
- (BOOL)prepareAfterBinded;
- (void)resetAfterDisconnected;
- (void)resetAfterShutdowned;

@end

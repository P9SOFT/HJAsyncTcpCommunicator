//
//  HJAsyncTcpCommunicateManager.h
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import Foundation;
#import <Hydra/Hydra.h>
#import "HJAsyncTcpCommunicateDogma.h"
#import "HJAsyncTcpCommunicateExecutor.h"

#define     HJAsyncTcpCommunicateManagerNotification    @"HJAsyncTcpCommunicateManagerNotification"

#define     HJAsyncTcpCommunicateManagerParameterKeyServerKey       @"HJAsyncTcpCommunicateManagerParameterKeyServerKey"
#define     HJAsyncTcpCommunicateManagerParameterKeyEvent           @"HJAsyncTcpCommunicateManagerParameterKeyEvent"
#define     HJAsyncTcpCommunicateManagerParameterKeyHeaderObject    @"HJAsyncTcpCommunicateManagerParameterKeyHeaderObject"
#define     HJAsyncTcpCommunicateManagerParameterKeyBodyObject      @"HJAsyncTcpCommunicateManagerParameterKeyBodyObject"
#define     HJAsyncTcpCommunicateManagerParameterKeyReferenceResult @"HJAsyncTcpCommunicateManagerParameterKeyReferenceResult"

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateManagerEvent)
{
    HJAsyncTcpCommunicateManagerEventDummy,
    HJAsyncTcpCommunicateManagerEventConnected,
    HJAsyncTcpCommunicateManagerEventConnectFailed,
    HJAsyncTcpCommunicateManagerEventDisconnected,
    HJAsyncTcpCommunicateManagerEventSent,
    HJAsyncTcpCommunicateManagerEventSendFailed,
    HJAsyncTcpCommunicateManagerEventReceived
};

@interface HJAsyncTcpCommunicateManager : HYManager

+ (HJAsyncTcpCommunicateManager * _Nonnull)defaultHJAsyncTcpCommunicateManager;

- (BOOL)standbyWithWorkerName:(NSString * _Nonnull)workerName;

- (void)setServerAddress:(NSString * _Nonnull)address port:(NSNumber * _Nonnull)port forKey:(NSString * _Nonnull)key;
- (NSString * _Nullable)serverAddressForKey:(NSString * _Nonnull)key;
- (NSNumber * _Nullable)serverPortForKey:(NSString * _Nonnull)key;
- (void)removeServerForKey:(NSString * _Nonnull)key;
- (void)removeAllServers;
- (BOOL)isConnectingForServerKey:(NSString * _Nonnull)key;

- (void)connectToServerKey:(NSString * _Nonnull)key timeout:(NSTimeInterval)timeout dogma:(id _Nonnull)dogma connectHandler:(HJAsyncTcpCommunicatorHandler _Nullable)connectHandler receiveHandler:(HJAsyncTcpCommunicatorHandler _Nullable)receiveHandler disconnect:(HJAsyncTcpCommunicatorHandler _Nullable)disconnectHandler;
- (void)sendHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject toServerKey:(NSString * _Nonnull)key completion:(HJAsyncTcpCommunicatorHandler _Nullable)completion;
- (void)disconnectFromServerKey:(NSString * _Nonnull)key;

@property (nonatomic, readonly) BOOL standby;

@end

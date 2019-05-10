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
#define     HJAsyncTcpCommunicateManagerParameterKeyClientKey       @"HJAsyncTcpCommunicateManagerParameterKeyClientKey"
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
    HJAsyncTcpCommunicateManagerEventReceived,
    HJAsyncTcpCommunicateManagerEventBinded,
    HJAsyncTcpCommunicateManagerEventBindFailed,
    HJAsyncTcpCommunicateManagerEventAccepted,
    HJAsyncTcpCommunicateManagerEventShutdowned
};

@interface HJAsyncTcpCommunicateManager : HYManager

+ (HJAsyncTcpCommunicateManager * _Nonnull)defaultHJAsyncTcpCommunicateManager;

- (BOOL)standbyWithWorkerName:(NSString * _Nullable)workerName;

- (BOOL)setServerInfo:(HJAsyncTcpServerInfo * _Nullable)serverInfo forServerKey:(NSString * _Nullable)serverKey;
- (HJAsyncTcpServerInfo * _Nullable)serverInfoForServerKey:(NSString * _Nullable)serverKey;
- (void)removeServerInfoForServerKey:(NSString * _Nullable)serverKey;
- (void)removeAllServerInfos;

- (void)connect:(NSString * _Nullable)serverKey
        timeout:(NSTimeInterval)timeout
          dogma:(id _Nullable)dogma
        connect:(HJAsyncTcpCommunicatorHandler _Nullable)connectHandler
        receive:(HJAsyncTcpCommunicatorHandler _Nullable)receiveHandler
     disconnect:(HJAsyncTcpCommunicatorHandler _Nullable)disconnectHandler;

- (void)bind:(NSString * _Nullable)serverKey
     backlog:(NSUInteger)backlog
       dogma:(id _Nullable)dogma
        bind:(HJAsyncTcpCommunicatorHandler _Nullable)bindHandler
      accept:(HJAsyncTcpCommunicatorHandler _Nullable)acceptHandler
     receive:(HJAsyncTcpCommunicatorHandler _Nullable)receiveHandler
  disconnect:(HJAsyncTcpCommunicatorHandler _Nullable)disconnectHandler
    shutdown:(HJAsyncTcpCommunicatorHandler _Nullable)shutdownHandler;

- (void)sendHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject toClientKey:(NSString * _Nullable)clientKey completion:(HJAsyncTcpCommunicatorHandler _Nullable)completion;
- (void)broadcastHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject toServerKey:(NSString * _Nullable)serverKey;

- (void)disconnectClientForClientKey:(NSString * _Nullable)clientKey;
- (void)disconnectAllClientsAtServerKey:(NSString * _Nullable)serverKey;
- (void)shutdownServerForServerKey:(NSString * _Nullable)serverKey;

- (void)setServerAcceptable:(BOOL)acceptable forServerKey:(NSString * _Nullable)serverKey;
- (BOOL)isAcceptableForServerKey:(NSString * _Nullable)serverKey;
- (BOOL)isConnectingForClientKey:(NSString * _Nullable)clientKey;
- (BOOL)isBindingForServerKey:(NSString * _Nullable)serverKey;
- (NSInteger)countOfClientsAtServerForServerKey:(NSString * _Nullable)serverKey;
- (HJAsyncTcpServerInfo * _Nullable)serverInfoForClientKey:(NSString * _Nullable)clientKey;

@property (nonatomic, readonly) BOOL standby;

@end

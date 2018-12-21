//
//  HJAsyncTcpCommunicateExecutor.h
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 4. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import Foundation;
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <Hydra/Hydra.h>

#define     HJAsyncTcpCommunicateExecutorName                           @"HJAsyncTcpCommunicateExecutorName"

#define     HJAsyncTcpCommunicateExecutorParameterKeyOperation              @"HJAsyncTcpCommunicateExecutorParameterKeyOperation"
#define     HJAsyncTcpCommunicateExecutorParameterKeyEvent                  @"HJAsyncTcpCommunicateExecutorParameterKeyEvent"
#define     HJAsyncTcpCommunicateExecutorParameterKeyServerKey              @"HJAsyncTcpCommunicateExecutorParameterKeyServerKey"
#define     HJAsyncTcpCommunicateExecutorParameterKeyServerInfo             @"HJAsyncTcpCommunicateExecutorParameterKeyServerInfo"
#define     HJAsyncTcpCommunicateExecutorParameterKeyTimeout                @"HJAsyncTcpCommunicateExecutorParameterKeyTimeout"
#define     HJAsyncTcpCommunicateExecutorParameterKeySockfd                 @"HJAsyncTcpCommunicateExecutorParameterKeySockfd"
#define     HJAsyncTcpCommunicateExecutorParameterKeyDogma                  @"HJAsyncTcpCommunicateExecutorParameterKeyDogma"
#define     HJAsyncTcpCommunicateExecutorParameterKeyHandshakeParameter     @"HJAsyncTcpCommunicateExecutorParameterKeyHandshakeParameter"
#define     HJAsyncTcpCommunicateExecutorParameterKeyHandshakeObject        @"HJAsyncTcpCommunicateExecutorParameterKeyHandshakeObject"
#define     HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject           @"HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject"
#define     HJAsyncTcpCommunicateExecutorParameterKeyBodyObject             @"HJAsyncTcpCommunicateExecutorParameterKeyBodyObject"
#define     HJAsyncTcpCommunicateExecutorParameterKeyUnintended             @"HJAsyncTcpCommunicateExecutorParameterKeyUnintended"
#define     HJAsyncTcpCommunicateExecutorParameterKeyDelayedConnectNotify   @"HJAsyncTcpCommunicateExecutorParameterKeyDelayedConnectNotify"
#define     HJAsyncTcpCommunicateExecutorParameterKeyConnectHandler         @"HJAsyncTcpCommunicateExecutorParameterKeyConnectHandler"
#define     HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler         @"HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler"
#define     HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler      @"HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler"
#define     HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler      @"HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler"

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateExecutorOperation)
{
    HJAsyncTcpCommunicateExecutorOperationDummy,
    HJAsyncTcpCommunicateExecutorOperationConnect,
    HJAsyncTcpCommunicateExecutorOperationDisconnect,
    HJAsyncTcpCommunicateExecutorOperationSend,
    HJAsyncTcpCommunicateExecutorOperationReceive
};

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateExecutorEvent)
{
    HJAsyncTcpCommunicateExecutorEventDummy,
    HJAsyncTcpCommunicateExecutorEventConnected,
    HJAsyncTcpCommunicateExecutorEventInHandshaking,
    HJAsyncTcpCommunicateExecutorEventReceived,
    HJAsyncTcpCommunicateExecutorEventSent,
    HJAsyncTcpCommunicateExecutorEventDisconnected,
    HJAsyncTcpCommunicateExecutorEventUnknownOperation,
    HJAsyncTcpCommunicateExecutorEventInvalidParameter,
    HJAsyncTcpCommunicateExecutorEventEmptyData,
    HJAsyncTcpCommunicateExecutorEventInvalidServerAddress,
    HJAsyncTcpCommunicateExecutorEventAlreadyConnected,
    HJAsyncTcpCommunicateExecutorEventNetworkError,
    HJAsyncTcpCommunicateExecutorEventInternalError,
    HJAsyncTcpCommunicateExecutorEventCanceled,
    HJAsyncTcpCommunicateExecutorEventExpired
};

@interface HJAsyncTcpServerInfo : NSObject

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSNumber *port;
@property (nonatomic, strong) NSDictionary *parameters;

@end

@interface HJAsyncTcpCommunicateExecutor : HYExecuter

- (BOOL)haveSockfdForServerKey:(NSString * _Nullable)key;

@property (nonatomic, readonly) NSUInteger readBuffSize;

@end

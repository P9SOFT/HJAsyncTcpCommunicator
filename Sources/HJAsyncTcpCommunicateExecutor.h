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
#define     HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair  @"HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair"
#define     HJAsyncTcpCommunicateExecutorParameterKeyTimeout                @"HJAsyncTcpCommunicateExecutorParameterKeyTimeout"
#define     HJAsyncTcpCommunicateExecutorParameterKeySockfd                 @"HJAsyncTcpCommunicateExecutorParameterKeySockfd"
#define     HJAsyncTcpCommunicateExecutorParameterKeyDogma                  @"HJAsyncTcpCommunicateExecutorParameterKeyDogma"
#define     HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject           @"HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject"
#define     HJAsyncTcpCommunicateExecutorParameterKeyBodyObject             @"HJAsyncTcpCommunicateExecutorParameterKeyBodyObject"
#define     HJAsyncTcpCommunicateExecutorParameterKeyUnintended             @"HJAsyncTcpCommunicateExecutorParameterKeyUnintended"
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

@interface HJAsyncTcpCommunicateExecutor : HYExecuter

- (BOOL)haveSockfdForServerAddressPortPair:(NSArray * _Nonnull)pair;

@end

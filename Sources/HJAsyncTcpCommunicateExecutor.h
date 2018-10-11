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

#define     HJAsyncTcpCommunicateExecutorParameterKeyOperation          @"HJAsyncTcpCommunicateExecutorParameterKeyOperation"
#define     HJAsyncTcpCommunicateExecutorParameterKeyStatus             @"HJAsyncTcpCommunicateExecutorParameterKeyStatus"
#define     HJAsyncTcpCommunicateExecutorParameterKeyServerAddress      @"HJAsyncTcpCommunicateExecutorParameterKeyServerAddress"
#define     HJAsyncTcpCommunicateExecutorParameterKeyServerPort         @"HJAsyncTcpCommunicateExecutorParameterKeyServerPort"
#define     HJAsyncTcpCommunicateExecutorParameterKeyTimeout            @"HJAsyncTcpCommunicateExecutorParameterKeyTimeout"
#define     HJAsyncTcpCommunicateExecutorParameterKeySockfd             @"HJAsyncTcpCommunicateExecutorParameterKeySockfd"
#define     HJAsyncTcpCommunicateExecutorParameterKeyDogma              @"HJAsyncTcpCommunicateExecutorParameterKeyDogma"
#define     HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject       @"HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject"
#define     HJAsyncTcpCommunicateExecutorParameterKeyBodyObject         @"HJAsyncTcpCommunicateExecutorParameterKeyBodyObject"
#define     HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler     @"HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler"
#define     HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler  @"HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler"
#define     HJAsyncTcpCommunicateExecutorParameterKeyCompletion         @"HJAsyncTcpCommunicateExecutorParameterKeyCompletion"

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateExecutorOperation)
{
    HJAsyncTcpCommunicateExecutorOperationDummy,
    HJAsyncTcpCommunicateExecutorOperationConnect,
    HJAsyncTcpCommunicateExecutorOperationDisconnect,
    HJAsyncTcpCommunicateExecutorOperationDisconnected,
    HJAsyncTcpCommunicateExecutorOperationSend,
    HJAsyncTcpCommunicateExecutorOperationReceive
};

typedef NS_ENUM(NSInteger, HJAsyncTcpCommunicateExecutorStatus)
{
    HJAsyncTcpCommunicateExecutorStatusDummy,
    HJAsyncTcpCommunicateExecutorStatusSucceed,
    HJAsyncTcpCommunicateExecutorStatusBrokenPacket,
    HJAsyncTcpCommunicateExecutorStatusUnknownOperation,
    HJAsyncTcpCommunicateExecutorStatusInvalidParameter,
    HJAsyncTcpCommunicateExecutorStatusInvalidServerAddress,
    HJAsyncTcpCommunicateExecutorStatusAlreadyConnected,
    HJAsyncTcpCommunicateExecutorStatusNotConnected,
    HJAsyncTcpCommunicateExecutorStatusNetworkError,
    HJAsyncTcpCommunicateExecutorStatusInternalError,
    HJAsyncTcpCommunicateExecutorStatusCanceled,
    HJAsyncTcpCommunicateExecutorStatusExpired,
    HJAsyncTcpCommunicateExecutorStatusError
};


@interface HJAsyncTcpCommunicateExecutor : HYExecuter

- (BOOL)haveSockfdForServerAddress:(NSString *)address withPort:(NSUInteger)port;

@end

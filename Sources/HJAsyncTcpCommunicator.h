//
//  HJAsyncTcpCommunicator.h
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import Foundation;
#import <Hydra/Hydra.h>

#define     HJAsyncTcpCommunicatorName      @"HJAsyncTcpCommunicatorName"

@interface HJAsyncTcpCommunicator : HYWorker

- (void)setServerAddress:(NSString * _Nullable)address port:(NSUInteger)port forKey:(NSString * _Nullable)key;
- (void)removeServerAddressForKey:(NSString * _Nullable)key;
- (void)removeAllServerAddresses;

- (void)connectToServerKey:(NSString * _Nullable)key timeout:(NSTimeInterval)timeout dogma:(id _Nullable)dogma receiveHandler:(void(^_Nullable)(BOOL, id _Nullable , id _Nullable ))receiveHandler disconnectHandler:(void(^_Nullable)(BOOL))disconnectHandler completion:(void(^_Nullable)(BOOL))completion;
- (void)writeToServerKey:(NSString * _Nullable)key headerObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject completion:(void(^_Nullable)(BOOL))completion;
- (void)disconnectFromServerKey:(NSString * _Nullable)key;
- (void)isConnectedWithServerKey:(NSString * _Nullable)key completion:(void(^_Nullable)(BOOL))completion;

@end

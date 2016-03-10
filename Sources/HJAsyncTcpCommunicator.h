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

- (void)setServerAddress:(NSString *)address port:(NSUInteger)port forKey:(NSString *)key;
- (void)removeServerAddressForKey:(NSString *)key;
- (void)removeAllServerAddresses;

- (void)connectToServerKey:(NSString *)key timeout:(NSTimeInterval)timeout dogma:(id)dogma receiveHandler:(void(^)(BOOL, id, id))receiveHandler disconnectHandler:(void(^)(BOOL))disconnectHandler completion:(void(^)(BOOL))completion;
- (void)writeToServerKey:(NSString *)key headerObject:(id)headerObject bodyObject:(id)bodyObject completion:(void(^)(BOOL))completion;
- (void)disconnectFromServerKey:(NSString *)key;
- (void)isConnectedWithServerKey:(NSString *)key completion:(void(^)(BOOL))completion;

@end

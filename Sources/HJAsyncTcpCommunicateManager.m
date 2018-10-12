//
//  HJAsyncTcpCommunicateManager.m
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJAsyncTcpCommunicateExecutor.h"
#import "HJAsyncTcpCommunicateManager.h"

@interface HJAsyncTcpCommunicateManager ()
{
    NSMutableDictionary             *_servers;
    NSString                        *_workerName;
    HJAsyncTcpCommunicateExecutor   *_executor;
}

- (NSMutableDictionary *)executorHandlerWithResult:(HYResult *)result;

@end

@implementation HJAsyncTcpCommunicateManager

- (NSString *)name
{
    return HJAsyncTcpCommunicateManagerNotification;
}

- (NSString *)brief
{
    return @"HJAsyncTcpCommunicateManager";
}

+ (HJAsyncTcpCommunicateManager *)defaultHJAsyncTcpCommunicateManager
{
    static dispatch_once_t once;
    static HJAsyncTcpCommunicateManager *sharedInstance;
    dispatch_once(&once, ^{ sharedInstance = [[self alloc] init];});
    return sharedInstance;
}

- (BOOL)standbyWithWorkerName:(NSString *)workerName
{
    if( (self.standby == YES) || (workerName.length == 0) ) {
        return NO;
    }
    if( (_servers = [[NSMutableDictionary alloc] init]) == nil ) {
        return NO;
    }
    if( (_executor = [[HJAsyncTcpCommunicateExecutor alloc] init]) == nil ) {
        return NO;
    }
    if( [self registExecuter:_executor withWorkerName:workerName action:@selector(executorHandlerWithResult:)] == NO ) {
        return NO;
    }
    _workerName = workerName;
    _standby = YES;
    return YES;
}

- (NSMutableDictionary *)executorHandlerWithResult:(HYResult *)result
{
    return nil;
}

- (void)setServerAddress:(NSString *)address port:(NSNumber *)port forKey:(NSString *)key
{
    if( (address.length == 0) || (port == nil) || (key.length == 0) ) {
        return;
    }
    @synchronized(self) {
        _servers[key] = @[address, port];
    }
}

- (NSString *)serverAddressForKey:(NSString *)key
{
    if( key.length == 0 ) {
        return nil;
    }
    NSString *address = nil;
    @synchronized(self) {
        NSArray *pair = _servers[key];
        if( pair.count != 2 ) {
            return nil;
        }
        address = pair[0];
    }
    return address;
}

- (NSNumber *)serverPortForKey:(NSString *)key
{
    if( key.length == 0 ) {
        return nil;
    }
    NSNumber *port = nil;
    @synchronized(self) {
        NSArray *pair = _servers[key];
        if( pair.count != 2 ) {
            return nil;
        }
        port = pair[1];
    }
    return port;
}

- (void)removeServerForKey:(NSString *)key
{
    if( key.length == 0 ) {
        return;
    }
    @synchronized(self) {
        [self disconnectFromServerKey:key completion:nil];
        [_servers removeObjectForKey:key];
    }
}

- (void)removeAllServers
{
    @synchronized(self) {
        for( NSString *key in _servers ) {
            [self disconnectFromServerKey:key completion:nil];
        }
        [_servers removeAllObjects];
    }
}

- (void)connectToServerKey:(NSString * _Nonnull)key timeout:(NSTimeInterval)timeout dogma:(id _Nonnull)dogma connectHandler:(HJAsyncTcpCommunicatorHandler _Nullable)connectHandler receiveHandler:(HJAsyncTcpCommunicatorHandler _Nullable)receiveHandler disconnect:(HJAsyncTcpCommunicatorHandler _Nullable)disconnectHandler
{
    NSArray *pair = nil;
    if( (self.standby == YES) && (key.length > 0) && ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == YES) ) {
        @synchronized(self) {
            pair = _servers[key];
        }
    }
    if( pair == nil ) {
        if( connectHandler != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                connectHandler(NO, nil, nil);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName: HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationConnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:pair forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
    [query setParameter:@(timeout) forKey:HJAsyncTcpCommunicateExecutorParameterKeyTimeout];
    [query setParameter:dogma forKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    [query setParameter:connectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyConnectHandler];
    [query setParameter:receiveHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    [query setParameter:disconnectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)sendHeaderObject:(id)headerObject bodyObject:(id)bodyObject toServerKey:(NSString *)key completion:(HJAsyncTcpCommunicatorHandler)completion
{
    NSArray *pair = nil;
    if( (self.standby == YES) && (key.length > 0) && ((headerObject != nil) || (bodyObject != nil)) ) {
        @synchronized(self) {
            pair = _servers[key];
        }
    }
    if( pair == nil ) {
        if( completion != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, nil);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationSend) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:pair forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [query setParameter:completion forKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)disconnectFromServerKey:(NSString *)key completion:(HJAsyncTcpCommunicatorHandler)completion
{
    NSArray *pair = nil;
    if( (self.standby == YES) && (key.length > 0) ) {
        @synchronized(self) {
            pair = _servers[key];
        }
    }
    if( pair == nil ) {
        if( completion != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, nil);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationDisconnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:pair forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
    [query setParameter:completion forKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (BOOL)isConnectdForServerKey:(NSString *)key
{
    NSArray *pair = nil;
    if( (self.standby == YES) && (key.length > 0) ) {
        @synchronized(self) {
            pair = _servers[key];
        }
    }
    if( pair == nil ) {
        return NO;
    }
    return [_executor haveSockfdForServerAddressPortPair:pair];
}

@end
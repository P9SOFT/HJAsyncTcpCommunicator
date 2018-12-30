//
//  HJAsyncTcpCommunicateManager.m
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

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
    NSString *key = [result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    if( key.length == 0 ) {
        return nil;
    }
    HJAsyncTcpCommunicateExecutorOperation operation = (HJAsyncTcpCommunicateExecutorOperation)[[result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation] integerValue];
    HJAsyncTcpCommunicateExecutorEvent event = (HJAsyncTcpCommunicateExecutorEvent)[[result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyEvent] integerValue];
    id headerObject = [result parameterForKey:HJAsyncTcpCommunicateManagerParameterKeyHeaderObject];
    id bodyObject = [result parameterForKey:HJAsyncTcpCommunicateManagerParameterKeyBodyObject];
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
    
    paramDict[HJAsyncTcpCommunicateManagerParameterKeyServerKey] = key;
    paramDict[HJAsyncTcpCommunicateManagerParameterKeyReferenceResult] = result;
    
    switch( operation ) {
        case HJAsyncTcpCommunicateExecutorOperationConnect :
            paramDict[HJAsyncTcpCommunicateManagerParameterKeyEvent] = (event == HJAsyncTcpCommunicateExecutorEventConnected) ? @(HJAsyncTcpCommunicateManagerEventConnected) : @(HJAsyncTcpCommunicateManagerEventConnectFailed);
            break;
        case HJAsyncTcpCommunicateExecutorOperationDisconnect :
            paramDict[HJAsyncTcpCommunicateManagerParameterKeyEvent] = @(HJAsyncTcpCommunicateManagerEventDisconnected);
            break;
        case HJAsyncTcpCommunicateExecutorOperationSend :
            paramDict[HJAsyncTcpCommunicateManagerParameterKeyEvent] = (event == HJAsyncTcpCommunicateExecutorEventSent) ? @(HJAsyncTcpCommunicateManagerEventSent) : @(HJAsyncTcpCommunicateManagerEventSendFailed);
            break;
        case HJAsyncTcpCommunicateExecutorOperationReceive :
            paramDict[HJAsyncTcpCommunicateManagerParameterKeyEvent] = @(HJAsyncTcpCommunicateManagerEventReceived);
            if( headerObject != nil ) {
                paramDict[HJAsyncTcpCommunicateManagerParameterKeyHeaderObject] = headerObject;
            }
            if( bodyObject != nil ) {
                paramDict[HJAsyncTcpCommunicateManagerParameterKeyBodyObject] = bodyObject;
            }
            break;
        default :
            [paramDict removeAllObjects];
            break;
    }
    
    if( paramDict.count == 0 ) {
        return nil;
    }
    
    return paramDict;
}

- (BOOL)setServerAddress:(NSString *)address port:(NSNumber *)port parameters:(NSDictionary *)parameters forKey:(NSString *)key
{
    if( (address.length == 0) || (port == nil) || (key.length == 0) ) {
        return NO;
    }
    HJAsyncTcpServerInfo *info = [HJAsyncTcpServerInfo new];
    info.address = address;
    info.port = port;
    info.parameters = parameters;
    @synchronized(self) {
        _servers[key] = info;
    }
    return YES;
}

- (HJAsyncTcpServerInfo *)serverInfoForKey:(NSString *)key
{
    if( key.length == 0 ) {
        return nil;
    }
    HJAsyncTcpServerInfo *info = nil;
    @synchronized(self) {
        info = _servers[key];
    }
    return info;
}

- (void)removeServerForKey:(NSString *)key
{
    if( key.length == 0 ) {
        return;
    }
    @synchronized(self) {
        [self disconnectFromServerForKey:key];
        [_servers removeObjectForKey:key];
    }
}

- (void)removeAllServers
{
    @synchronized(self) {
        for( NSString *key in _servers ) {
            [self disconnectFromServerForKey:key];
        }
        [_servers removeAllObjects];
    }
}

- (BOOL)isConnectingForServerKey:(NSString *)key
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    if( info == nil ) {
        return NO;
    }
    return [_executor haveSockfdForServerKey:key];
}

- (void)connectToServerKey:(NSString *)key timeout:(NSTimeInterval)timeout dogma:(id)dogma connectHandler:(HJAsyncTcpCommunicatorHandler)connectHandler receiveHandler:(HJAsyncTcpCommunicatorHandler)receiveHandler disconnect:(HJAsyncTcpCommunicatorHandler)disconnectHandler
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) && ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == YES) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    if( info == nil ) {
        if( connectHandler != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                connectHandler(NO, nil, nil);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName: HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationConnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:key forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:@(timeout) forKey:HJAsyncTcpCommunicateExecutorParameterKeyTimeout];
    [query setParameter:dogma forKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    [query setParameter:connectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyConnectHandler];
    [query setParameter:receiveHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    [query setParameter:disconnectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)sendHeaderObject:(id)headerObject bodyObject:(id)bodyObject toServerKey:(NSString *)key completion:(HJAsyncTcpCommunicatorHandler)completion
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) && ((headerObject != nil) || (bodyObject != nil)) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    if( info == nil ) {
        if( completion != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, nil);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationSend) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:key forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [query setParameter:completion forKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)disconnectFromServerForKey:(NSString *)key
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    if( info == nil ) {
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationDisconnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:key forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [[Hydra defaultHydra] pushQuery:query];
}

@end

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
    NSString *clientKey = (NSString *)[result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyClientKey];
    id headerObject = [result parameterForKey:HJAsyncTcpCommunicateManagerParameterKeyHeaderObject];
    id bodyObject = [result parameterForKey:HJAsyncTcpCommunicateManagerParameterKeyBodyObject];
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
    
    paramDict[HJAsyncTcpCommunicateManagerParameterKeyServerKey] = key;
    if( clientKey.length > 0 ) {
        paramDict[HJAsyncTcpCommunicateManagerParameterKeyClientKey] = clientKey;
    }
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
        case HJAsyncTcpCommunicateExecutorOperationBind :
            paramDict[HJAsyncTcpCommunicateManagerParameterKeyEvent] = (event == HJAsyncTcpCommunicateExecutorEventBinded) ? @(HJAsyncTcpCommunicateManagerEventBinded) : @(HJAsyncTcpCommunicateManagerEventBindFailed);
            break;
        case HJAsyncTcpCommunicateExecutorOperationAccept :
            paramDict[HJAsyncTcpCommunicateManagerParameterKeyEvent] = @(HJAsyncTcpCommunicateManagerEventAccepted);
            break;
        case HJAsyncTcpCommunicateExecutorOperationShutdown :
            paramDict[HJAsyncTcpCommunicateManagerParameterKeyEvent] = @(HJAsyncTcpCommunicateManagerEventShutdowned);
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
    info.serverMode = NO;
    info.acceptable = YES;
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

- (BOOL)isConnectingServerForKey:(NSString *)key
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
    if( info.serverMode == YES ) {
        return NO;
    }
    return [_executor haveSockfdForServerKey:key];
}

- (BOOL)isBindingServerForKey:(NSString *)key
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
    if( info.serverMode == NO ) {
        return NO;
    }
    return [_executor haveSockfdForServerKey:key];
}

- (void)connectToServerKey:(NSString *)key
                   timeout:(NSTimeInterval)timeout
                     dogma:(id)dogma
                   connect:(HJAsyncTcpCommunicatorHandler)connectHandler
                   receive:(HJAsyncTcpCommunicatorHandler)receiveHandler
                disconnect:(HJAsyncTcpCommunicatorHandler)disconnectHandler
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) && ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == YES) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    switch( [dogma supportMode] ) {
        case HJAsyncTcpCommunicateDogmaSupportModeClient :
        case HJAsyncTcpCommunicateDogmaSupportModeClientAndServer :
            break;
        default :
            info = nil;
            break;
    }
    if( info == nil ) {
        if( connectHandler != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                connectHandler(NO, key, nil, nil);
            });
        }
        return;
    }
    info.serverMode = NO;
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
                completion(NO, key, headerObject, bodyObject);
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

- (void)bindServerKey:(NSString *)key
              backlog:(NSUInteger)backlog
                dogma:(id)dogma
                 bind:(HJAsyncTcpCommunicatorHandler)bindHandler
               accept:(HJAsyncTcpCommunicatorHandler)acceptHandler
              receive:(HJAsyncTcpCommunicatorHandler)receiveHandler
           disconnect:(HJAsyncTcpCommunicatorHandler)disconnectHandler
             shutdown:(HJAsyncTcpCommunicatorHandler)shutdownHandler
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) && ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == YES) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    switch( [dogma supportMode] ) {
        case HJAsyncTcpCommunicateDogmaSupportModeServer :
        case HJAsyncTcpCommunicateDogmaSupportModeClientAndServer :
            break;
        default :
            info = nil;
            break;
    }
    if( info == nil ) {
        if( bindHandler != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                bindHandler(NO, key, nil, nil);
            });
        }
        return;
    }
    info.serverMode = YES;
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName: HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationBind) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:key forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:@(backlog) forKey:HJAsyncTcpCommunicateExecutorParameterKeyBacklog];
    [query setParameter:dogma forKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    [query setParameter:bindHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyBindHandler];
    [query setParameter:acceptHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyAcceptHandler];
    [query setParameter:receiveHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    [query setParameter:disconnectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    [query setParameter:shutdownHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyShutdownHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)sendHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject toServerKey:(NSString * _Nonnull)serverKey clientKey:(NSString *)clientKey completion:(HJAsyncTcpCommunicatorHandler _Nullable)completion
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (serverKey.length > 0) && (clientKey.length > 0) && ((headerObject != nil) || (bodyObject != nil)) ) {
        @synchronized(self) {
            info = _servers[serverKey];
        }
    }
    if( info == nil ) {
        if( completion != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, clientKey, headerObject, bodyObject);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationSend) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:serverKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:clientKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyClientKey];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [query setParameter:completion forKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)broadcastHeaderObject:(id _Nullable)headerObject bodyObject:(id _Nullable)bodyObject toServerKey:(NSString * _Nonnull)key
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) && ((headerObject != nil) || (bodyObject != nil)) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    if( info == nil ) {
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationBroadcast) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:key forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)closeClientForKey:(NSString * _Nonnull)clientKey atServerKey:(NSString *)serverKey
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (serverKey.length > 0) ) {
        @synchronized(self) {
            info = _servers[serverKey];
        }
    }
    if( info == nil ) {
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationDisconnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:serverKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:clientKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyClientKey];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)closeAllClientsAtServerKey:(NSString * _Nonnull)key
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
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationCloseAllClient) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:key forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [[Hydra defaultHydra] pushQuery:query];
}

- (BOOL)serverAcceptableForKey:(NSString * _Nonnull)key
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
    return info.acceptable;
}

- (void)setServerAcceptable:(BOOL)acceptable forKey:(NSString * _Nonnull)key
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
    info.acceptable = acceptable;
}

- (NSInteger)countOfClientsAtServerForKey:(NSString * _Nonnull)key
{
    HJAsyncTcpServerInfo *info = nil;
    if( (self.standby == YES) && (key.length > 0) ) {
        @synchronized(self) {
            info = _servers[key];
        }
    }
    if( info == nil ) {
        return 0;
    }
    return [_executor countOfSockfdForServerKey:key];
}

- (void)shutdownServerForKey:(NSString * _Nonnull)key
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
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationShutdown) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:key forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:info forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [[Hydra defaultHydra] pushQuery:query];
}

@end

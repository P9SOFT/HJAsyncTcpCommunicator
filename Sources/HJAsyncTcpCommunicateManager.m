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
    NSMutableDictionary             *_serverInfos;
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
    if( (_serverInfos = [[NSMutableDictionary alloc] init]) == nil ) {
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
    NSString *serverKey = (NSString *)[result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    NSString *clientKey = (NSString *)[result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyClientKey];
    HJAsyncTcpCommunicateExecutorOperation operation = (HJAsyncTcpCommunicateExecutorOperation)[[result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation] integerValue];
    HJAsyncTcpCommunicateExecutorEvent event = (HJAsyncTcpCommunicateExecutorEvent)[[result parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyEvent] integerValue];
    id headerObject = [result parameterForKey:HJAsyncTcpCommunicateManagerParameterKeyHeaderObject];
    id bodyObject = [result parameterForKey:HJAsyncTcpCommunicateManagerParameterKeyBodyObject];
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
    
    if( serverKey.length > 0 ) {
        paramDict[HJAsyncTcpCommunicateManagerParameterKeyServerKey] = serverKey;
    }
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

- (BOOL)setServerInfo:(HJAsyncTcpServerInfo *)serverInfo forServerKey:(NSString *)serverKey
{
    if( (serverInfo.address.length == 0) || (serverInfo.port == nil) || (serverKey.length == 0) ) {
        return NO;
    }
    @synchronized(self) {
        _serverInfos[serverKey] = serverInfo;
    }
    return YES;
}

- (HJAsyncTcpServerInfo *)serverInfoForServerKey:(NSString *)serverKey
{
    if( serverKey.length == 0 ) {
        return nil;
    }
    HJAsyncTcpServerInfo *severInfo = nil;
    @synchronized(self) {
        severInfo = _serverInfos[serverKey];
    }
    return severInfo;
}

- (void)removeServerInfoForServerKey:(NSString *)serverKey
{
    if( serverKey.length == 0 ) {
        return;
    }
    @synchronized(self) {
        [_serverInfos removeObjectForKey:serverKey];
    }
}

- (void)removeAllServerInfos
{
    @synchronized(self) {
        [_serverInfos removeAllObjects];
    }
}

- (void)connect:(NSString *)serverKey
        timeout:(NSTimeInterval)timeout
          dogma:(id)dogma
        connect:(HJAsyncTcpCommunicatorHandler)connectHandler
        receive:(HJAsyncTcpCommunicatorHandler)receiveHandler
     disconnect:(HJAsyncTcpCommunicatorHandler)disconnectHandler
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) && ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == YES) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    switch( [dogma supportMode] ) {
        case HJAsyncTcpCommunicateDogmaSupportModeClient :
        case HJAsyncTcpCommunicateDogmaSupportModeClientAndServer :
            break;
        default :
            serverInfo = nil;
            break;
    }
    if( serverInfo == nil ) {
        if( connectHandler != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                connectHandler(NO, serverKey, nil, nil);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName: HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationConnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:serverKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:serverInfo forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:@(timeout) forKey:HJAsyncTcpCommunicateExecutorParameterKeyTimeout];
    [query setParameter:dogma forKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    [query setParameter:connectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyConnectHandler];
    [query setParameter:receiveHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    [query setParameter:disconnectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)bind:(NSString *)serverKey
     backlog:(NSUInteger)backlog
       dogma:(id)dogma
        bind:(HJAsyncTcpCommunicatorHandler)bindHandler
      accept:(HJAsyncTcpCommunicatorHandler)acceptHandler
     receive:(HJAsyncTcpCommunicatorHandler)receiveHandler
  disconnect:(HJAsyncTcpCommunicatorHandler)disconnectHandler
    shutdown:(HJAsyncTcpCommunicatorHandler)shutdownHandler
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) && ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == YES) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    switch( [dogma supportMode] ) {
        case HJAsyncTcpCommunicateDogmaSupportModeServer :
        case HJAsyncTcpCommunicateDogmaSupportModeClientAndServer :
            break;
        default :
            serverInfo = nil;
            break;
    }
    if( serverInfo == nil ) {
        if( bindHandler != nil ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                bindHandler(NO, serverKey, nil, nil);
            });
        }
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName: HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationBind) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:serverKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:serverInfo forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    [query setParameter:@(backlog) forKey:HJAsyncTcpCommunicateExecutorParameterKeyBacklog];
    [query setParameter:dogma forKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    [query setParameter:bindHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyBindHandler];
    [query setParameter:acceptHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyAcceptHandler];
    [query setParameter:receiveHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    [query setParameter:disconnectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    [query setParameter:shutdownHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyShutdownHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)sendHeaderObject:(id)headerObject bodyObject:(id)bodyObject toClientKey:(NSString *)clientKey completion:(HJAsyncTcpCommunicatorHandler)completion
{
    if( (self.standby == NO) || (clientKey.length == 0) || ((headerObject == nil) && (bodyObject == nil)) ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(NO, clientKey, headerObject, bodyObject);
        });
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationSend) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:clientKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyClientKey];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [query setParameter:completion forKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)broadcastHeaderObject:(id)headerObject bodyObject:(id)bodyObject toServerKey:(NSString *)serverKey
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) && ((headerObject != nil) || (bodyObject != nil)) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    if( serverInfo == nil ) {
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationBroadcast) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:serverKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)disconnectClientForClientKey:(NSString *)clientKey
{
    if( (self.standby == NO) || (clientKey.length == 0) ) {
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationDisconnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:clientKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyClientKey];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)disconnectAllClientsAtServerKey:(NSString *)serverKey;
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    if( serverInfo == nil ) {
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationDisconnectAll) forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:serverKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)shutdownServerForServerKey:(NSString *)serverKey;
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    if( serverInfo == nil ) {
        return;
    }
    HYQuery *query = [HYQuery queryWithWorkerName:_workerName executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)HJAsyncTcpCommunicateExecutorOperationShutdown) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:serverKey forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)setServerAcceptable:(BOOL)acceptable forServerKey:(NSString *)serverKey
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    if( serverInfo == nil ) {
        return;
    }
    serverInfo.disableAccept = !acceptable;
}

- (BOOL)isAcceptableForServerKey:(NSString *)serverKey
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    if( serverInfo == nil ) {
        return NO;
    }
    return !serverInfo.disableAccept;
}

- (BOOL)isConnectingForClientKey:(NSString *)clientKey
{
    return [_executor haveSockfdForKey:clientKey];
}

- (BOOL)isBindingForServerKey:(NSString *)serverKey
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    if( serverInfo == nil ) {
        return NO;
    }
    return [_executor haveSockfdForKey:serverKey];
}

- (NSInteger)countOfClientsAtServerForServerKey:(NSString * _Nullable)serverKey
{
    HJAsyncTcpServerInfo *serverInfo = nil;
    if( (self.standby == YES) && (serverKey.length > 0) ) {
        @synchronized(self) {
            serverInfo = _serverInfos[serverKey];
        }
    }
    if( serverInfo == nil ) {
        return 0;
    }
    return [_executor countOfSockfdForServerKey:serverKey];
}

- (HJAsyncTcpServerInfo *)serverInfoForClientKey:(NSString * _Nullable)clientKey
{
    if( clientKey.length == 0 ) {
        return nil;
    }
    return [_executor serverInfoForClientKey:clientKey];
}

@end

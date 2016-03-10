//
//  HJAsyncTcpCommunicator.m
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 9. 9.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJAsyncTcpCommunicateDogma.h"
#import "HJAsyncTcpCommunicateExecutor.h"
#import "HJAsyncTcpCommunicator.h"

@interface HJAsyncTcpCommunicator ()
{
    NSMutableDictionary *_serverAddressForName;
}
@end

@implementation HJAsyncTcpCommunicator

- (NSString *)name
{
    return HJAsyncTcpCommunicatorName;
}

- (NSString *)brief
{
    return @"HJAsyncTcpCommunicator for TCP/IP socket communication.";
}

- (BOOL)didInit
{
    if( (_serverAddressForName = [NSMutableDictionary new]) == nil ) {
        return NO;
    }
    if( [self addExecuter:[[HJAsyncTcpCommunicateExecutor alloc] init]] == NO ) {
        return NO;
    }
    
    return YES;
}

- (void)setServerAddress:(NSString *)address port:(NSUInteger)port forKey:(NSString *)key
{
    if( ([address length] == 0) || (port == 0) || ([key length] == 0) ) {
        return;
    }
    
    @synchronized(self) {
        [_serverAddressForName setObject:@[address, @(port)] forKey:key];
    }
}

- (void)removeServerAddressForKey:(NSString *)key
{
    if( [key length] == 0 ) {
        return;
    }
    
    @synchronized(self) {
        [_serverAddressForName removeObjectForKey:key];
    }
}

- (void)removeAllServerAddresses
{
    @synchronized(self) {
        [_serverAddressForName removeAllObjects];
    }
}

- (void)connectToServerKey:(NSString *)key timeout:(NSTimeInterval)timeout dogma:(id)dogma receiveHandler:(void(^)(BOOL, id, id))receiveHandler disconnectHandler:(void(^)(BOOL))disconnectHandler completion:(void(^)(BOOL))completion
{
    NSString *address = nil;
    NSNumber *port = nil;
    if( [key length] > 0 ) {
        @synchronized(self) {
            address = [[_serverAddressForName objectForKey:key] objectAtIndex:0];
            port = [[_serverAddressForName objectForKey:key] objectAtIndex:1];
        }
    }
    if( ([address length] == 0) || (port == nil) || (dogma == nil) || (receiveHandler == nil) ) {
        if( completion != nil ) {
            completion(NO);
        }
        return;
    }
    
    HYQuery *query = [HYQuery queryWithWorkerName:self.name executerName: HJAsyncTcpCommunicateExecutorName];
    [query setParameter:[NSNumber numberWithInteger:(NSInteger)HJAsyncTcpCommunicateExecutorOperationConnect] forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:address forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
    [query setParameter:port forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerPort];
    [query setParameter:@(timeout) forKey:HJAsyncTcpCommunicateExecutorParameterKeyTimeout];
    [query setParameter:dogma forKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    [query setParameter:receiveHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    [query setParameter:disconnectHandler forKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    [query setParameter:completion forKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletion];
    [self pushQuery:query];
}

- (void)writeToServerKey:(NSString *)key headerObject:(id)headerObject bodyObject:(id)bodyObject completion:(void(^)(BOOL))completion
{
    NSString *address = nil;
    NSNumber *port = nil;
    if( [key length] > 0 ) {
        @synchronized(self) {
            address = [[_serverAddressForName objectForKey:key] objectAtIndex:0];
            port = [[_serverAddressForName objectForKey:key] objectAtIndex:1];
        }
    }
    if( ([address length] == 0) || (port == nil) || ((headerObject == nil) && (bodyObject == nil)) ) {
        if( completion != nil ) {
            completion(NO);
        }
        return;
    }
    
    HYQuery *query = [HYQuery queryWithWorkerName:self.name executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:[NSNumber numberWithInteger:(NSInteger)HJAsyncTcpCommunicateExecutorOperationSend] forKey: HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:address forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
    [query setParameter:port forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerPort];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [query setParameter:completion forKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletion];
    [self pushQuery:query];
}

- (void)disconnectFromServerKey:(NSString *)key
{
    NSString *address = nil;
    NSNumber *port = nil;
    if( [key length] > 0 ) {
        @synchronized(self) {
            address = [[_serverAddressForName objectForKey:key] objectAtIndex:0];
            port = [[_serverAddressForName objectForKey:key] objectAtIndex:1];
        }
    }
    if( ([address length] == 0) || (port == nil) ) {
        return;
    }
    
    HYQuery *query = [HYQuery queryWithWorkerName:self.name executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:[NSNumber numberWithInteger:(NSInteger)HJAsyncTcpCommunicateExecutorOperationDisconnect] forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:address forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
    [query setParameter:port forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerPort];
    [self pushQuery:query];
}

- (void)isConnectedWithServerKey:(NSString *)key completion:(void(^)(BOOL))completion
{
    ;
}

@end

//
//  HJAsyncTcpCommunicateExecutor.m
//  HJBox
//
//  Created by Tae Hyun Na on 2013. 4. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJAsyncTcpCommunicateDogma.h"
#import "HJAsyncTcpCommunicateExecutor.h"

#define kDefaultBufferSize  8192

@implementation HJAsyncTcpServerInfo
@end

@interface HJAsyncTcpCommunicateExecutor ()
{
    NSMutableDictionary *_dogmas;
    NSMutableDictionary *_sockets;
    NSMutableDictionary *_serverInfos;
    unsigned char       *_writeBuffer;
    NSUInteger          _sizeOfWriteBuffer;
}

- (BOOL)prepareWriteBufferForSize:(NSUInteger)sizeOfWriteBuffer;
- (HYResult *)resultForQuery:(id)anQuery withEvent:(HJAsyncTcpCommunicateExecutorEvent)event;
- (void)pushQueryForWithOperation:(HJAsyncTcpCommunicateExecutorOperation)operation header:(id)headerObject body:(id)bodyObject anQuery:(id)anQyery;
- (void)storeResultWithEvent:(HJAsyncTcpCommunicateExecutorEvent)event query:(id)anQuery flag:(BOOL)flag completion:(HJAsyncTcpCommunicatorHandler)completion;
- (void)connectWithQuery:(id)anQuery;
- (void)sendWithQuery:(id)anQuery;
- (void)receiveWithQuery:(id)anQuery;
- (void)disconnectWithQuery:(id)anQuery;
- (void)reader:(id)anQuery;

@end

@implementation HJAsyncTcpCommunicateExecutor

- (instancetype)init
{
    if( (self = [super init]) != nil ) {
        _writeBuffer = NULL;
        _sizeOfWriteBuffer = 0;
        if( (_dogmas = [NSMutableDictionary new]) == nil ) {
            return nil;
        }
        if( (_sockets = [NSMutableDictionary new]) == nil ) {
            return nil;
        }
        if( (_serverInfos = [NSMutableDictionary new]) == nil ) {
            return nil;
        }
        _readBuffSize = kDefaultBufferSize;
    }
    return self;
}

- (void)dealloc
{
    if( _writeBuffer != NULL ) {
        free(_writeBuffer);
        _writeBuffer = NULL;
        _sizeOfWriteBuffer = 0;
    }
}

- (NSString *)name
{
    return HJAsyncTcpCommunicateExecutorName;
}

- (NSString *)brief
{
    return @"HJAyncTcpCommunicator's executor for handling transfer based on TCP/IP.";
}

- (BOOL)haveSockfdForServerKey:(NSString *)key
{
    if( key.length == 0 ) {
        return NO;
    }
    BOOL have = NO;
    @synchronized(self) {
        have = (_sockets[key] != nil);
    }
    return have;
}

- (BOOL)calledExecutingWithQuery:(id)anQuery
{
    HJAsyncTcpCommunicateExecutorOperation operation = (HJAsyncTcpCommunicateExecutorOperation)[[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation] integerValue];
    switch( operation ) {
        case HJAsyncTcpCommunicateExecutorOperationConnect :
            [self connectWithQuery:anQuery];
            break;
        case HJAsyncTcpCommunicateExecutorOperationSend :
            [self sendWithQuery:anQuery];
            break;
        case HJAsyncTcpCommunicateExecutorOperationReceive :
            [self receiveWithQuery:anQuery];
            break;
        case HJAsyncTcpCommunicateExecutorOperationDisconnect :
            [self disconnectWithQuery:anQuery];
            break;
        default :
            [self storeResult:[self resultForQuery:anQuery withEvent:HJAsyncTcpCommunicateExecutorEventUnknownOperation]];
            break;
    }
    return YES;
}

- (BOOL)calledCancelingWithQuery:(id)anQuery
{
    [self storeResult:[self resultForQuery:anQuery withEvent:HJAsyncTcpCommunicateExecutorEventCanceled]];
    return YES;
}

- (BOOL)prepareWriteBufferForSize:(NSUInteger)sizeOfWriteBuffer
{
    if( _writeBuffer == NULL ) {
        if( (_writeBuffer = (unsigned char *)malloc((size_t)sizeOfWriteBuffer)) != NULL ) {
            _sizeOfWriteBuffer = sizeOfWriteBuffer;
        }
    } else {
        if( sizeOfWriteBuffer > _sizeOfWriteBuffer ) {
            if( (_writeBuffer = (unsigned char *)realloc(_writeBuffer, (size_t)sizeOfWriteBuffer)) != NULL ) {
                _sizeOfWriteBuffer = sizeOfWriteBuffer;
            }
        }
    }
    if( _writeBuffer == NULL ) {
        _sizeOfWriteBuffer = 0;
    }
    return (_writeBuffer != NULL);
}

- (id)resultForExpiredQuery:(id)anQuery
{
    return [self resultForQuery:anQuery withEvent:HJAsyncTcpCommunicateExecutorEventExpired];
}

- (HYResult *)resultForQuery:(id)anQuery withEvent:(HJAsyncTcpCommunicateExecutorEvent)event
{
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) != nil ) {
        [result setParametersFromDictionary:[anQuery paramDict]];
        [result setParameter:@(event) forKey:HJAsyncTcpCommunicateExecutorParameterKeyEvent];
    }
    return result;
}

- (void)pushQueryForWithOperation:(HJAsyncTcpCommunicateExecutorOperation)operation header:(id)headerObject body:(id)bodyObject anQuery:(id)anQyery
{
    HYQuery *query = [HYQuery queryWithWorkerName:self.name executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParametersFromDictionary:[anQyery paramDict]];
    [query setParameter:@((NSInteger)operation) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [self.employedWorker pushQuery:query];
}

- (void)storeResultWithEvent:(HJAsyncTcpCommunicateExecutorEvent)event query:(id)anQuery flag:(BOOL)flag completion:(HJAsyncTcpCommunicatorHandler)completion
{
    if( completion != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(flag, nil, nil);
        });
    }
    [self storeResult:[self resultForQuery:anQuery withEvent:event]];
}

- (void)connectWithQuery:(id)anQuery
{
    HJAsyncTcpCommunicatorHandler connectHandler = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyConnectHandler];
    if( [[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDelayedConnectNotify] boolValue] == YES ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventConnected query:anQuery flag:YES completion:connectHandler];
        return;
    }
    HJAsyncTcpServerInfo *info = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerInfo];
    id dogma = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    if( (info.address.length == 0) || (info.port.unsignedIntegerValue == 0) || ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == NO) ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInvalidParameter query:anQuery flag:NO completion:connectHandler];
        return;
    }
    NSString *key = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    if( _sockets[key] != nil ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventAlreadyConnected query:anQuery flag:NO completion:connectHandler];
        return;
    }
    struct hostent *phostipref;
    if( (phostipref = gethostbyname(info.address.UTF8String)) == NULL ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInvalidServerAddress query:anQuery flag:NO completion:connectHandler];
        return;
    }
    int sockfd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if( sockfd < 0 ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    int flags = fcntl( sockfd, F_GETFL );
    if( fcntl( sockfd, F_SETFL, flags|O_NONBLOCK ) < 0 ) {
        close(sockfd);
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    
    struct sockaddr_in servaddr;
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons((in_port_t)info.port.unsignedIntegerValue);
    memcpy(&(servaddr.sin_addr), phostipref->h_addr, phostipref->h_length);
    if( connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0 ) {
        if( errno != EINPROGRESS ) {
            close(sockfd);
            [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventNetworkError query:anQuery flag:NO completion:connectHandler];
            return;
        }
    }
    
    NSTimeInterval timeout = (NSTimeInterval)[[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyTimeout] doubleValue];
    fd_set rset, wset;
    FD_ZERO(&rset);
    FD_SET(sockfd, &rset);
    wset = rset;
    double sec, usec;
    usec = modf((double)timeout, &sec);
    usec *= 100000;
    struct timeval tv;
    tv.tv_sec = (__darwin_time_t)sec;
    tv.tv_usec = (__darwin_suseconds_t)usec;
    
    if( select(sockfd+1, &rset, &wset, NULL, &tv) == 0 ) {
        close(sockfd);
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    
    flags = fcntl( sockfd, F_GETFL );
    if( fcntl( sockfd, F_SETFL, flags&~O_NONBLOCK ) < 0 ) {
        close(sockfd);
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    
    if( [dogma prepareAfterConnected] == NO ) {
        close(sockfd);
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInternalError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    
    @synchronized(self) {
        _dogmas[key] = dogma;
        _sockets[key] = @(sockfd);
        _serverInfos[key] = info;
    }
    
    [anQuery setParameter:@(sockfd) forKey:HJAsyncTcpCommunicateExecutorParameterKeySockfd];
    
    if( [dogma needHandshake:anQuery] == NO ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventConnected query:anQuery flag:YES completion:connectHandler];
    } else {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInHandshaking query:anQuery flag:YES completion:nil];
        id handshakeObject = [dogma firstHandshakeObjectAfterConnected:anQuery];
        if( handshakeObject != nil ) {
            [anQuery setParameter:handshakeObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHandshakeObject];
            [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationSend header:handshakeObject body:nil anQuery:anQuery];
        }
    }
    
    [NSThread detachNewThreadSelector:@selector(reader:) toTarget:self withObject:anQuery];
}

- (void)sendWithQuery:(id)anQuery
{
    NSString *key = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    id dogma = nil;
    NSNumber *sockfdNumber = nil;
    @synchronized(self) {
        dogma = _dogmas[key];
        sockfdNumber = _sockets[key];
    }
    HJAsyncTcpCommunicatorHandler completion = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler];
    if( (dogma == nil) || (sockfdNumber.intValue == 0) ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInvalidParameter query:anQuery flag:NO completion:completion];
        return;
    }
    BOOL inHandshaking = [dogma needHandshake:anQuery];
    id headerObject = nil;
    id bodyObject = nil;
    NSUInteger length = 0;
    if( inHandshaking == YES ) {
        headerObject = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyHandshakeObject];
        if( headerObject == nil ) {
            [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInvalidParameter query:anQuery flag:NO completion:completion];
            return;
        }
        length = [dogma lengthOfHandshakeFromHandshakeObject:headerObject];
    } else {
        headerObject = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
        bodyObject = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
        if( (headerObject == nil) && (bodyObject == nil) ) {
            [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInvalidParameter query:anQuery flag:NO completion:completion];
            return;
        }
        length = [dogma lengthOfHeaderFromHeaderObject:headerObject] + [dogma lengthOfBodyFromBodyObject:bodyObject];
    }
    if( length == 0 ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventEmptyData query:anQuery flag:NO completion:completion];
        return;
    }
    
    id fragmentHandler = [dogma fragmentHandlerFromHeaderObject: headerObject bodyObject:bodyObject];
    if( fragmentHandler == nil ) {
        if( [self prepareWriteBufferForSize:length] == NO ) {
            [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInternalError query:anQuery flag:NO completion:completion];
            return;
        }
        NSUInteger wbytes = [dogma writeBuffer:_writeBuffer bufferLength:length fromHeaderObject:headerObject bodyObject:bodyObject fragmentHandler:nil];
        if( wbytes == 0 ) {
            [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventEmptyData query:anQuery flag:NO completion:completion];
            return;
        }
        if( (wbytes = (int)write(sockfdNumber.intValue, _writeBuffer, wbytes)) <= 0 ) {
            [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventNetworkError query:anQuery flag:NO completion:completion];
            return;
        }
    } else {
        if( [fragmentHandler conformsToProtocol:@protocol(HJAsyncTcpCommunicateFragmentHandlerProtocol)] == NO ) {
            [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInternalError query:anQuery flag:NO completion:completion];
            return;
        }
        while( [fragmentHandler haveWritableFragment] == YES ) {
            NSUInteger fragmentlen = [fragmentHandler reserveFragment];
            if( [self prepareWriteBufferForSize:fragmentlen] == NO ) {
                [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventInternalError query:anQuery flag:NO completion:completion];
                return;
            }
            NSUInteger wbytes = [dogma writeBuffer:_writeBuffer bufferLength:fragmentlen fromHeaderObject:headerObject bodyObject:bodyObject fragmentHandler:fragmentHandler];
            if( wbytes == 0 ) {
                [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventEmptyData query:anQuery flag:NO completion:completion];
                return;
            }
            if( (wbytes = (int)write(sockfdNumber.intValue, _writeBuffer, wbytes)) <= 0 ) {
                [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventNetworkError query:anQuery flag:NO completion:completion];
                return;
            }
            [fragmentHandler flushFragment];
        }
    }
    
    if( (inHandshaking == NO) && ([dogma isControlHeaderObject:headerObject] == NO) ) {
        [self storeResultWithEvent:HJAsyncTcpCommunicateExecutorEventSent query:anQuery flag:YES completion:completion];
    }
}

- (void)receiveWithQuery:(id)anQuery
{
    [self storeResult:[self resultForQuery:anQuery withEvent:HJAsyncTcpCommunicateExecutorEventReceived]];
}

- (void)disconnectWithQuery:(id)anQuery
{
    if( [[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyUnintended] boolValue] == YES ) {
        [self storeResult:[self resultForQuery:anQuery withEvent:HJAsyncTcpCommunicateExecutorEventDisconnected]];
        return;
    }
    NSString *key = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    NSNumber *sockfd = nil;
    @synchronized(self) {
        sockfd = _sockets[key];
    }
    if( sockfd == nil ) {
        [self storeResult:[self resultForQuery:anQuery withEvent:HJAsyncTcpCommunicateExecutorEventInvalidParameter]];
        return;
    }
    close(sockfd.intValue);
}

- (void)reader:(id)anQuery
{
    NSString *key = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerKey];
    id dogma = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    int sockfd = [[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeySockfd] intValue];
    HJAsyncTcpCommunicatorHandler receiveHandler = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    HJAsyncTcpCommunicatorHandler disconnectHandler = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    NSMutableData *receivedData = [[NSMutableData alloc] init];
    unsigned char rbuff[self.readBuffSize];
    int rbytes = 0;
    BOOL gotBrokenPacket = NO;
    NSUInteger lengthOfHeader = 0;
    NSUInteger lengthOfBody = 0;
    id headerObject = nil;
    id bodyObject = nil;
    
    while( 1 ) {
        @autoreleasepool {
            if( (rbytes = (int)read(sockfd, rbuff, self.readBuffSize)) <= 0 ) {
                break;
            }
            [receivedData appendBytes:rbuff length:rbytes];
            if( [dogma needHandshake:anQuery] == YES ) {
                if( headerObject == nil ) {
                    if( (lengthOfHeader = [dogma lengthOfHandshakeFromStream:(unsigned char *)receivedData.bytes streamLength:receivedData.length appendedLength:(NSUInteger)rbytes]) == 0 ) {
                        break;
                    }
                    headerObject = [dogma handshakeObjectFromHeaderStream:(unsigned char *)receivedData.bytes streamLength:lengthOfHeader];
                    if( [dogma isBrokenHandshakeObject:headerObject] == YES ) {
                        gotBrokenPacket = YES;
                        break;
                    }
                    [receivedData replaceBytesInRange:NSMakeRange(0, lengthOfHeader) withBytes:NULL length:0];
                    id handshakeObject = [dogma nextHandshakeObjectAfterUpdateHandshakeStatusFromObject:headerObject];
                    if( handshakeObject != nil ) {
                        [anQuery setParameter:handshakeObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHandshakeObject];
                        [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationSend header:handshakeObject body:nil anQuery:anQuery];
                    }
                }
                if( headerObject != nil ) {
                    if( [dogma needHandshake:anQuery] == NO ) {
                        [anQuery setParameter:@(1) forKey:HJAsyncTcpCommunicateExecutorParameterKeyDelayedConnectNotify];
                        [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationConnect header:nil body:nil anQuery:anQuery];
                    }
                    headerObject = nil;
                    bodyObject = nil;
                }
            } else {
                switch( [dogma methodType] ) {
                    case HJAsyncTcpCommunicateDogmaMethodTypeHeaderWithBody :
                        while( receivedData.length > 0 ) {
                            if( headerObject == nil ) {
                                if( (lengthOfHeader = [dogma lengthOfHeaderFromStream:(unsigned char *)receivedData.bytes streamLength:receivedData.length appendedLength:(NSUInteger)rbytes]) == 0 ) {
                                    break;
                                }
                                headerObject = [dogma headerObjectFromHeaderStream:(unsigned char *)receivedData.bytes streamLength:lengthOfHeader];
                                if( [dogma isBrokenHeaderObject:headerObject] == YES ) {
                                    gotBrokenPacket = YES;
                                    break;
                                }
                                [receivedData replaceBytesInRange:NSMakeRange(0, lengthOfHeader) withBytes:NULL length:0];
                                if( [dogma isControlHeaderObject:headerObject] == YES ) {
                                    id controlObject = [dogma controlHeaderObjectHandling:headerObject];
                                    if( controlObject != nil ) {
                                        [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationSend header:controlObject body:nil anQuery:anQuery];
                                    }
                                    headerObject = nil;
                                }
                            }
                            if( headerObject != nil ) {
                                lengthOfBody = [dogma lengthOfBodyFromHeaderObject:headerObject];
                                if( receivedData.length < lengthOfBody ) {
                                    break;
                                }
                                if( lengthOfBody > 0 ) {
                                    bodyObject = [dogma bodyObjectFromBodyStream:(unsigned char *)receivedData.bytes streamLength:lengthOfBody headerObject:headerObject];
                                    if( [dogma isBrokenBodyObject:bodyObject] == YES ) {
                                        gotBrokenPacket = YES;
                                        break;
                                    }
                                    [receivedData replaceBytesInRange:NSMakeRange(0, lengthOfBody) withBytes:NULL length:0];
                                } else {
                                    bodyObject = nil;
                                }
                                if( receiveHandler != nil ) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        receiveHandler(YES, headerObject, bodyObject);
                                    });
                                }
                                [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationReceive header:headerObject body:bodyObject anQuery:anQuery];
                                lengthOfBody = 0;
                                headerObject = nil;
                                bodyObject = nil;
                            }
                        }
                        break;
                    case HJAsyncTcpCommunicateDogmaMethodTypeBodyWithEof :
                        while( (lengthOfBody = [dogma lengthOfBodyFromStream:(unsigned char *)receivedData.bytes streamLength:receivedData.length appendedLength:(NSUInteger)rbytes]) > 0 ) {
                            bodyObject = [dogma bodyObjectFromBodyStream:(unsigned char *)receivedData.bytes streamLength:lengthOfBody headerObject:nil];
                            if( [dogma isBrokenBodyObject:bodyObject] == YES ) {
                                gotBrokenPacket = YES;
                                break;
                            }
                            [receivedData replaceBytesInRange:NSMakeRange(0, lengthOfBody) withBytes:NULL length:0];
                            if( receiveHandler != nil ) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    receiveHandler(YES, nil, bodyObject);
                                });
                            }
                            [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationReceive header:nil body:bodyObject anQuery:anQuery];
                            bodyObject = nil;
                        }
                        break;
                    default :
                        bodyObject = [NSData dataWithBytes:receivedData.bytes length:receivedData.length];
                        [receivedData replaceBytesInRange:NSMakeRange(0, receivedData.length) withBytes:NULL length:receivedData.length];
                        if( receiveHandler != nil ) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                receiveHandler(YES, nil, bodyObject);
                            });
                        }
                        [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationReceive header:nil body:bodyObject anQuery:anQuery];
                        break;
                }
            }
            if( gotBrokenPacket == YES ) {
                break;
            }
        }
    }
    
    close(sockfd);
    
    [dogma resetAfterDisconnected];
    
    if( key.length > 0 ) {
        @synchronized(self) {
            [_dogmas removeObjectForKey:key];
            [_sockets removeObjectForKey:key];
            [_serverInfos removeObjectForKey:key];
        }
    }
    if( disconnectHandler != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            disconnectHandler(YES, nil, nil);
        });
    }
    [anQuery setParameter:@(1) forKey:HJAsyncTcpCommunicateExecutorParameterKeyUnintended];
    [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationDisconnect header:nil body:bodyObject anQuery:anQuery];
}

@end

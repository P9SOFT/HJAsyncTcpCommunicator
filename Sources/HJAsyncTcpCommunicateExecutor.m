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

@interface HJAsyncTcpCommunicateExecutor ()
{
    NSMutableDictionary *_dogmas;
    NSMutableDictionary *_sockets;
    NSMutableDictionary *_addressForSocket;
    unsigned char       *_writeBuffer;
    NSUInteger          _sizeOfWriteBuffer;
}

- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJAsyncTcpCommunicateExecutorStatus)status;
- (void)pushQueryForWithOperation:(HJAsyncTcpCommunicateExecutorOperation)operation header:(id)headerObject body:(id)bodyObject sockfd:(int)sockfd;
- (NSString *)addressKeyFromServerAddress:(NSString *)serverAddress serverPort:(NSNumber *)serverPort;
- (NSString *)serverAddressFromAddresKey:(NSString *)addressKey;
- (NSNumber *)serverPortFromAddresKey:(NSString *)addressKey;
- (void)storeResultWithStatus:(HJAsyncTcpCommunicateExecutorStatus)status query:(id)anQuery flag:(BOOL)flag completion:(HJAsyncTcpCommunicatorHandler)completion;
- (void)connectWithQuery:(id)anQuery;
- (void)sendWithQuery:(id)anQuery;
- (void)receiveWithQuery:(id)anQuery;
- (void)disconnectWithQuery:(id)anQuery;

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
        if( (_addressForSocket = [NSMutableDictionary new]) == nil ) {
            return nil;
        }
    }
    return self;
}

- (NSString *)name
{
    return HJAsyncTcpCommunicateExecutorName;
}

- (NSString *)brief
{
    return @"HJAyncTcpCommunicator's executor for handling transfer based on TCP/IP.";
}

- (BOOL)haveSockfdForServerAddressPortPair:(NSArray *)pair
{
    if( pair.count != 2 ) {
        return NO;
    }
    if( ([pair[0] isKindOfClass:[NSString class]] == NO) || ([pair[1] isKindOfClass:[NSNumber class]] == NO) ) {
        return NO;
    }
    BOOL have = NO;
    NSString *addressKey = [self addressKeyFromServerAddress:pair[0] serverPort:pair[1]];
    @synchronized(self) {
        have = (_sockets[addressKey] != nil);
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
            [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusUnknownOperation]];
            break;
    }
    return YES;
}

- (BOOL)calledCancelingWithQuery:(id)anQuery
{
    [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusCanceled]];
    return YES;
}

- (id)resultForExpiredQuery:(id)anQuery
{
    return [self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusExpired];
}

- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJAsyncTcpCommunicateExecutorStatus)status
{
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) != nil ) {
        [result setParametersFromDictionary:[anQuery paramDict]];
        [result setParameter:@(status) forKey:HJAsyncTcpCommunicateExecutorParameterKeyStatus];
    }
    return result;
}

- (void)pushQueryForWithOperation:(HJAsyncTcpCommunicateExecutorOperation)operation header:(id)headerObject body:(id)bodyObject sockfd:(int)sockfd
{
    HYQuery *query = [HYQuery queryWithWorkerName:self.name executerName:HJAsyncTcpCommunicateExecutorName];
    [query setParameter:@((NSInteger)operation) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
    [query setParameter:headerObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    [query setParameter:bodyObject forKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    [query setParameter:@(sockfd) forKey:HJAsyncTcpCommunicateExecutorParameterKeySockfd];
    [self.employedWorker pushQuery:query];
}

- (NSString *)addressKeyFromServerAddress:(NSString *)serverAddress serverPort:(NSNumber *)serverPort
{
    return [NSString stringWithFormat:@"%@:%ld", serverAddress, (unsigned long)serverPort.unsignedIntegerValue];
}

- (NSString *)serverAddressFromAddresKey:(NSString *)addressKey
{
    if( addressKey.length == 0 ) {
        return nil;
    }
    NSArray *pair = [addressKey componentsSeparatedByString:@":"];
    if( pair.count != 2 ) {
        return nil;
    }
    return pair[0];
}

- (NSNumber *)serverPortFromAddresKey:(NSString *)addressKey
{
    if( addressKey.length == 0 ) {
        return nil;
    }
    NSArray *pair = [addressKey componentsSeparatedByString:@":"];
    if( pair.count != 2 ) {
        return nil;
    }
    return @([pair[1] unsignedIntegerValue]);
}

- (void)storeResultWithStatus:(HJAsyncTcpCommunicateExecutorStatus)status query:(id)anQuery flag:(BOOL)flag completion:(HJAsyncTcpCommunicatorHandler)completion
{
    if( completion != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(flag, nil, nil);
        });
    }
    [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter]];
}

- (void)connectWithQuery:(id)anQuery
{
    NSString *serverAddress = nil;
    NSNumber *serverPort = nil;
    NSArray *pair = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
    if( pair.count == 2) {
        serverAddress = pair[0];
        serverPort = pair[1];
    }
    NSTimeInterval timeout = (NSTimeInterval)[[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyTimeout] doubleValue];
    id dogma = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    HJAsyncTcpCommunicatorHandler connectHandler = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyConnectHandler];
    HJAsyncTcpCommunicatorHandler receiveHandler = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    HJAsyncTcpCommunicatorHandler disconnectHandler = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    if( (serverAddress == nil) || (serverPort == 0) || ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == NO) ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter query:anQuery flag:NO completion:connectHandler];
        return;
    }
    NSString *addressKey = [self addressKeyFromServerAddress:serverAddress serverPort:serverPort];
    if( _sockets[addressKey] != nil ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusAlreadyConnected query:anQuery flag:NO completion:connectHandler];
        return;
    }
    struct hostent *phostipref;
    if( (phostipref = gethostbyname(serverAddress.UTF8String)) == NULL ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidServerAddress query:anQuery flag:NO completion:connectHandler];
        return;
    }
    int sockfd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if( sockfd < 0 ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    int flags = fcntl( sockfd, F_GETFL );
    if( fcntl( sockfd, F_SETFL, flags|O_NONBLOCK ) < 0 ) {
        close(sockfd);
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    
    struct sockaddr_in servaddr;
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons((in_port_t)serverPort.unsignedIntegerValue);
    memcpy(&(servaddr.sin_addr), phostipref->h_addr, phostipref->h_length);
    if( connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0 ) {
        if( errno != EINPROGRESS ) {
            close(sockfd);
            [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:connectHandler];
            return;
        }
    }
    
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
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    
    flags = fcntl( sockfd, F_GETFL );
    if( fcntl( sockfd, F_SETFL, flags&~O_NONBLOCK ) < 0 ) {
        close(sockfd);
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:connectHandler];
        return;
    }
    
    @synchronized(self) {
        _dogmas[addressKey] = dogma;
        _sockets[addressKey] = @(sockfd);
        _addressForSocket[(@(sockfd)).stringValue] = addressKey;
    }
    
    [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusSucceed query:anQuery flag:YES completion:connectHandler];
    
    [NSThread detachNewThreadSelector:@selector(reader:) toTarget:self withObject:@{HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair:pair,
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeyDogma:dogma,
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeySockfd:@(sockfd),
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler:receiveHandler,
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler:disconnectHandler}];
}

- (void)sendWithQuery:(id)anQuery
{
    NSString *serverAddress = nil;
    NSNumber *serverPort = nil;
    NSArray *pair = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
    if( pair.count == 2) {
        serverAddress = pair[0];
        serverPort = pair[1];
    }
    id headerObject = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    id bodyObject = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    HJAsyncTcpCommunicatorHandler completion = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletionHandler];
    
    if( (serverAddress == nil) || (serverPort == nil) || ((headerObject == nil) && (bodyObject == nil)) ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter query:anQuery flag:NO completion:completion];
        return;
    }
    NSString *addressKey = [self addressKeyFromServerAddress:serverAddress serverPort:serverPort];
    id dogma = nil;
    NSNumber *sockfdNumber = nil;
    @synchronized(self) {
        dogma = _dogmas[addressKey];
        sockfdNumber = _sockets[addressKey];
    }
    if( (dogma == nil) || (sockfdNumber.intValue == 0) ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNotConnected query:anQuery flag:NO completion:completion];
        return;
    }
    
    NSUInteger length = [dogma lengthOfHeaderFromHeaderObject:headerObject] + [dogma lengthOfBodyFromBodyObject:bodyObject];
    if( length == 0 ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter query:anQuery flag:NO completion:completion];
        return;
    }
    
    if( _writeBuffer == NULL ) {
        if( (_writeBuffer = (unsigned char *)malloc((size_t)length)) != NULL ) {
            _sizeOfWriteBuffer = length;
        }
    } else {
        if( length > _sizeOfWriteBuffer ) {
            if( (_writeBuffer = (unsigned char *)realloc(_writeBuffer, (size_t)length)) != NULL ) {
                _sizeOfWriteBuffer = length;
            }
        }
    }
    if( _writeBuffer == NULL ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInternalError query:anQuery flag:NO completion:completion];
        return;
    }
    
    NSUInteger wbytes = [dogma writeBuffer:_writeBuffer bufferLength:length fromHeaderObject:headerObject bodyObject:bodyObject];
    if( wbytes == 0 ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter query:anQuery flag:NO completion:completion];
        return;
    }
    
    if( (wbytes = (int)write(sockfdNumber.intValue, _writeBuffer, wbytes)) <= 0 ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:completion];
        return;
    }
    
    [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusSucceed query:anQuery flag:YES completion:completion];
}

- (void)receiveWithQuery:(id)anQuery
{
    [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusSucceed]];
}

- (void)disconnectWithQuery:(id)anQuery
{
    NSString *serverAddress = nil;
    NSNumber *serverPort = nil;
    NSArray *pair = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
    if( pair.count == 2) {
        serverAddress = pair[0];
        serverPort = pair[1];
    }
    if( (serverAddress == nil) || (serverPort == nil) ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter]];
        return;
    }
    NSString *addressKey = [self addressKeyFromServerAddress:serverAddress serverPort:serverPort];
    NSNumber *sockfd = nil;
    @synchronized(self) {
        sockfd = _sockets[addressKey];
    }
    if( sockfd == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter]];
        return;
    }
    close(sockfd.intValue);
}

- (void)reader:(id)anParamter
{
    NSString *serverAddress = nil;
    NSNumber *serverPort = nil;
    NSArray *pair = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
    if( pair.count == 2) {
        serverAddress = pair[0];
        serverPort = pair[1];
    }
    id dogma = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    int sockfd = [anParamter[HJAsyncTcpCommunicateExecutorParameterKeySockfd] intValue];
    HJAsyncTcpCommunicatorHandler receiveHandler = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    HJAsyncTcpCommunicatorHandler disconnectHandler = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    NSMutableData *receivedData = [[NSMutableData alloc] init];
    unsigned char rbuff[kDefaultBufferSize];
    int rbytes = 0;
    BOOL gotBrokenPacket = NO;
    NSUInteger lengthOfHeader = 0;
    NSUInteger lengthOfBody = 0;
    id headerObject = nil;
    id bodyObject = nil;
    
    while( 1 ) {
        @autoreleasepool {
            if( (rbytes = (int)read(sockfd, rbuff, kDefaultBufferSize)) <= 0 ) {
                break;
            }
            [receivedData appendBytes:rbuff length:rbytes];
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
                            lengthOfBody = [dogma lengthOfBodyFromHeaderObject:headerObject];
                            [receivedData replaceBytesInRange:NSMakeRange(0, lengthOfHeader) withBytes:NULL length:0];
                            if( lengthOfBody == 0 ) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    receiveHandler(YES, headerObject, nil);
                                });
                                [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationReceive header:headerObject body:nil sockfd:sockfd];
                                headerObject = nil;
                            }
                        }
                        if( headerObject != nil ) {
                            if( receivedData.length < lengthOfBody ) {
                                break;
                            }
                            bodyObject = [dogma bodyObjectFromBodyStream:(unsigned char *)receivedData.bytes streamLength:lengthOfBody headerObject:headerObject];
                            if( [dogma isBrokenBodyObject:bodyObject] == YES ) {
                                gotBrokenPacket = YES;
                                break;
                            }
                            [receivedData replaceBytesInRange:NSMakeRange(0, lengthOfBody) withBytes:NULL length:0];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                receiveHandler(YES, headerObject, bodyObject);
                            });
                            [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationReceive header:headerObject body:bodyObject sockfd:sockfd];
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
                        dispatch_async(dispatch_get_main_queue(), ^{
                            receiveHandler(YES, nil, bodyObject);
                        });
                        [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationReceive header:nil body:bodyObject sockfd:sockfd];
                        bodyObject = nil;
                    }
                    break;
                default :
                    bodyObject = [NSData dataWithBytes:receivedData.bytes length:receivedData.length];
                    [receivedData replaceBytesInRange:NSMakeRange(0, receivedData.length) withBytes:NULL length:receivedData.length];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        receiveHandler(YES, nil, bodyObject);
                    });
                    [self pushQueryForWithOperation:HJAsyncTcpCommunicateExecutorOperationReceive header:nil body:bodyObject sockfd:sockfd];
                    break;
            }
            if( gotBrokenPacket == YES ) {
                break;
            }
        }
    }
    
    close(sockfd);
    
    NSString *addressKey = _addressForSocket[(@(sockfd)).stringValue];
    if( addressKey != nil ) {
        @synchronized(self) {
            [_dogmas removeObjectForKey:addressKey];
            [_addressForSocket removeObjectForKey:(@(sockfd)).stringValue];
            [_sockets removeObjectForKey:addressKey];
        }
    }
    if( disconnectHandler != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            disconnectHandler(YES, nil, nil);
        });
    }
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) != nil ) {
        [result setParameter:@(HJAsyncTcpCommunicateExecutorOperationDisconnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
        [result setParameter:@(HJAsyncTcpCommunicateExecutorStatusSucceed) forKey:HJAsyncTcpCommunicateExecutorParameterKeyStatus];
        [result setParameter:@[serverAddress, serverPort] forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddressPortPair];
        [self storeResult:result];
    }
}

@end

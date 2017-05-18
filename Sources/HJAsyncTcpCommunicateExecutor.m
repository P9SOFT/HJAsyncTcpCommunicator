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

@interface HJAsyncTcpCommunicateExecutor ()
{
    NSMutableDictionary *_dogmaForAddress;
    NSMutableDictionary *_socketForAddress;
    NSMutableDictionary *_addressForSocket;
    unsigned char       *_writeBuffer;
    NSUInteger          _sizeOfWriteBuffer;
}

- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJAsyncTcpCommunicateExecutorStatus)status;
- (void)pushQueryForWithOperation:(HJAsyncTcpCommunicateExecutorOperation)operation header:(id)headerObject body:(id)bodyObject sockfd:(int)sockfd;
- (NSString *)addressKeyFromServerAddress:(NSString *)serverAddress serverPort:(NSUInteger)serverPort;
- (NSString *)serverAddressFromAddresKey:(NSString *)addressKey;
- (NSNumber *)serverPortFromAddresKey:(NSString *)addressKey;
- (void)storeResultWithStatus:(HJAsyncTcpCommunicateExecutorStatus)status query:(id)anQuery flag:(BOOL)flag completion:(void(^)(BOOL))completion;
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
        if( (_dogmaForAddress = [NSMutableDictionary new]) == nil ) {
            return nil;
        }
        if( (_socketForAddress = [NSMutableDictionary new]) == nil ) {
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

- (NSString *)addressKeyFromServerAddress:(NSString *)serverAddress serverPort:(NSUInteger)serverPort
{
    return [NSString stringWithFormat:@"%@:%ld", serverAddress, (unsigned long)serverPort];
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
    
    return @([pair[1] integerValue]);
}

- (void)storeResultWithStatus:(HJAsyncTcpCommunicateExecutorStatus)status query:(id)anQuery flag:(BOOL)flag completion:(void(^)(BOOL))completion
{
    if( completion != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(flag);
        });
    }
    [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter]];
}

- (void)connectWithQuery:(id)anQuery
{
    NSString *serverAddress = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
    NSUInteger serverPort = [[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerPort] unsignedIntegerValue];
    NSTimeInterval timeout = (NSTimeInterval)[[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyTimeout] doubleValue];
    id dogma = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    void(^receiveHandler)(BOOL, id, id) = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    void(^disconnectHandler)(BOOL, id, id) = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    void(^completion)(BOOL) = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletion];
    
    if( (serverAddress == nil) || (serverPort == 0) || ([dogma isKindOfClass:[HJAsyncTcpCommunicateDogma class]] == NO) || (receiveHandler == nil) || (disconnectHandler == nil) ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter query:anQuery flag:NO completion:completion];
        return;
    }
    NSString *addressKey = [self addressKeyFromServerAddress:serverAddress serverPort:serverPort];
    if( _socketForAddress[addressKey] != nil ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusAlreadyConnected query:anQuery flag:NO completion:completion];
        return;
    }
    struct hostent *phostipref;
    if( (phostipref = gethostbyname(serverAddress.UTF8String)) == NULL ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidServerAddress query:anQuery flag:NO completion:completion];
        return;
    }
    int sockfd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if( sockfd < 0 ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:completion];
        return;
    }
    int flags = fcntl( sockfd, F_GETFL );
    if( fcntl( sockfd, F_SETFL, flags|O_NONBLOCK ) < 0 ) {
        close(sockfd);
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:completion];
        return;
    }
    
    struct sockaddr_in servaddr;
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons((in_port_t)serverPort);
    memcpy(&(servaddr.sin_addr), phostipref->h_addr, phostipref->h_length);
    if( connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0 ) {
        if( errno != EINPROGRESS ) {
            close(sockfd);
            [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:completion];
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
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:completion];
        return;
    }
    
    flags = fcntl( sockfd, F_GETFL );
    if( fcntl( sockfd, F_SETFL, flags&~O_NONBLOCK ) < 0 ) {
        close(sockfd);
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusNetworkError query:anQuery flag:NO completion:completion];
        return;
    }
    
    @synchronized(self) {
        _dogmaForAddress[addressKey] = dogma;
        _socketForAddress[addressKey] = @(sockfd);
        _addressForSocket[(@(sockfd)).stringValue] = addressKey;
    }
    
    [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusSucceed query:anQuery flag:YES completion:completion];
    
    [NSThread detachNewThreadSelector:@selector(reader:) toTarget:self withObject:@{HJAsyncTcpCommunicateExecutorParameterKeyServerAddress:serverAddress,
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeyServerPort:@(serverPort),
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeyDogma:dogma,
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeySockfd:@(sockfd),
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler:receiveHandler,
                                                                                    HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler:disconnectHandler}];
}

- (void)sendWithQuery:(id)anQuery
{
    NSString *serverAddress = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
    NSUInteger serverPort = [[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerPort] unsignedIntegerValue];
    id headerObject = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyHeaderObject];
    id bodyObject = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyBodyObject];
    void(^completion)(BOOL) = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyCompletion];
    
    if( (serverAddress == nil) || (serverPort == 0) || ((headerObject == nil) && (bodyObject == nil)) ) {
        [self storeResultWithStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter query:anQuery flag:NO completion:completion];
        return;
    }
    NSString *addressKey = [self addressKeyFromServerAddress:serverAddress serverPort:serverPort];
    id dogma = nil;
    NSNumber *sockfdNumber = nil;
    @synchronized(self) {
        dogma = _dogmaForAddress[addressKey];
        sockfdNumber = _socketForAddress[addressKey];
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
    NSString *serverAddress = [anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
    NSUInteger serverPort = [[anQuery parameterForKey:HJAsyncTcpCommunicateExecutorParameterKeyServerPort] unsignedIntegerValue];
    if( (serverAddress == nil) || (serverPort == 0) ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter]];
        return;
    }
    NSString *addressKey = [self addressKeyFromServerAddress:serverAddress serverPort:serverPort];
    NSNumber *sockfdNumber = nil;
    @synchronized(self) {
        sockfdNumber = _socketForAddress[addressKey];
    }
    if( sockfdNumber == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJAsyncTcpCommunicateExecutorStatusInvalidParameter]];
        return;
    }
    close(sockfdNumber.intValue);
}

- (void)reader:(id)anParamter
{
    NSString *serverAddress = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
    NSNumber *serverPort = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyServerPort];
    id dogma = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyDogma];
    int sockfd = [anParamter[HJAsyncTcpCommunicateExecutorParameterKeySockfd] intValue];
    void(^receiveHandler)(BOOL, id, id) = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyReceiveHandler];
    void(^disconnectHandler)(BOOL) = anParamter[HJAsyncTcpCommunicateExecutorParameterKeyDisconnectHandler];
    NSMutableData *receivedData = [[NSMutableData alloc] init];
    unsigned char rbuff[8192];
    int rbytes = 0;
    BOOL gotBrokenPacket = NO;
    NSUInteger lengthOfHeader = 0;
    NSUInteger lengthOfBody = 0;
    id headerObject = nil;
    id bodyObject = nil;
    
    while( 1 ) {
        @autoreleasepool {
            if( (rbytes = (int)read(sockfd, rbuff, 8192)) <= 0 ) {
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
            [_dogmaForAddress removeObjectForKey:addressKey];
            [_addressForSocket removeObjectForKey:(@(sockfd)).stringValue];
            [_socketForAddress removeObjectForKey:addressKey];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        disconnectHandler(YES);
    });
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) != nil ) {
        [result setParameter:@(HJAsyncTcpCommunicateExecutorOperationDisconnect) forKey:HJAsyncTcpCommunicateExecutorParameterKeyOperation];
        [result setParameter:@(HJAsyncTcpCommunicateExecutorStatusSucceed) forKey:HJAsyncTcpCommunicateExecutorParameterKeyStatus];
        [result setParameter:serverAddress forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerAddress];
        [result setParameter:serverPort forKey:HJAsyncTcpCommunicateExecutorParameterKeyServerPort];
        [self storeResult:result];
    }
}

@end

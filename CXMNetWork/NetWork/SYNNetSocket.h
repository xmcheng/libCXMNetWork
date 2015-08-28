//
//  SYNNetSocket.h
//  Synectics
//
//  Created by isoftpro on 14-4-19.
//  Copyright (c) 2014年 isoftpro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "SYNProtocol.h"

@interface SYNNetSocket : NSObject
{
@private
    //NSMutableArray* _requests;

    BOOL _isRunning;
    
    GCDAsyncSocket *_socket;
    
    
    
}
@property NSLock* socketLock;

@property NSString* appIp;

@property NSNumber* appPort;

- (void)sendId:(NSString*) dId From:(NSString*) f To:(NSString*) t SId:(int) sId Data:(NSData*) data ;
- (void)sendId:(NSString*) dId Data:(NSData*) data;
- (void)sendProtocol:(SYNProtocol*)synProtocol ;
- (void)sendNsData:(NSData*) protocolData;
- (void)closeSocket;
-(void)sendLOL;


@property NSString* ip ;
@property int port ;

- (void) connectServer;

- (void) connectServerAgain ;

@property int connState ;
@property int userState ;

@property int reConnCount;

@property BOOL reConnflag;

@property NSString * fromId;
@end

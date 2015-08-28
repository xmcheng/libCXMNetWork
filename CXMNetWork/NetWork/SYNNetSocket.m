//
//  SYNNetSocket.m
//  Synectics
//
//  Created by isoftpro on 14-4-19.
//  Copyright (c) 2014年 isoftpro. All rights reserved.
// 修改获取数据bug by chengxm 20141224
//2015.01.15 zk 重连后发送登陆协议

#import "SYNNetSocket.h"
#import "SYNDispatchProcessor.h"

//#define KEY_COMPLETE_HANDLER @"xxxxcc"
//#define KEY_REQUEST @"ososoccc"

#define HEADER_TAG 0
#define DATA_TAG 1
//0 表示原来协议解析方式  1表示修改后解析方式
#define PROTOCOL_TYPE 1

@implementation SYNNetSocket



- (id)init
{
    self = [super init];
        self.ip = @"121.42.27.87";
        self.port = 9997;

    self.connState = 0;
    self.userState = 0;
    _reConnflag=NO;
    return self;
}

-(void) connectServer
{
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                         delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error;
    [_socket connectToHost:self.ip onPort:self.port error:&error];
    if (error != nil)
    {
        self.connState = -1;
    }
    if(self.socketLock == nil)
    {
        self.socketLock = [[NSLock alloc] init];
    }
    
    if (!_reConnflag) {
        self.reConnCount=0;
    }
}

//$0477L0111
- (void)sendId:(NSString*) dId From:(NSString*) f To:(NSString*) t SId:(int) sId Data:(NSData*) data
{
    [self.socketLock lock];
    
    
    NSMutableString *head2 = [[NSMutableString alloc] initWithFormat:@"S"];
    [head2 appendString:f];
    while ([head2 length] < 21) {
        [head2 appendString:@" " ];
    }
    [head2 appendString:@"C"];
    [head2 appendString:t];
    while ([head2 length] < 42) {
        [head2 appendString:@" "];
    }
    
    //    NSString* head2 = [NSString stringWithFormat:@"S%20sC%20s",[f cStringUsingEncoding:NSUTF8StringEncoding] ,[t cStringUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableData *sIdData = [NSMutableData dataWithBytes: &sId length: sizeof(sId)];
    unsigned char tmp1 = ((unsigned char*)sIdData.mutableBytes)[0] ;
    unsigned char tmp2 = ((unsigned char*)sIdData.mutableBytes)[1] ;
    unsigned char tmp3 = ((unsigned char*)sIdData.mutableBytes)[2] ;
    unsigned char tmp4 = ((unsigned char*)sIdData.mutableBytes)[3] ;
    
    ((unsigned char*)sIdData.mutableBytes)[0] = tmp4;
    ((unsigned char*)sIdData.mutableBytes)[1] = tmp3;
    ((unsigned char*)sIdData.mutableBytes)[2] = tmp2;
    ((unsigned char*)sIdData.mutableBytes)[3] = tmp1;
    
    
    if (PROTOCOL_TYPE==1) {
        NSString* head = [NSString stringWithFormat:@"%@11",dId];
        NSData* len = [self intToNsdata:data.length+46];
        [_socket writeData:[@"$" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:0];
        [_socket writeData:len withTimeout:-1 tag:0];
        [_socket writeData:[head dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:0];
    }else
    {
        NSString* head = [NSString stringWithFormat:@"$%04d%@11",data.length+46,dId];
        [_socket writeData:[head dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:0];
        
    }
    
    [_socket writeData:[head2 dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:0];
    [_socket writeData:sIdData withTimeout:-1 tag:0];
    [_socket writeData:data withTimeout:-1 tag:0];
    [self.socketLock unlock];
}

//$0477L0111
- (void)sendId:(NSString*) dId Data:(NSData*) data
{
    
    @try {
        [self.socketLock lock];
       if( self.connState<0)
       {
           [self connectServer];
       }

        if(_socket==nil)
        {
            return;
        }
        
        if (PROTOCOL_TYPE==1) {
            NSData* len = [self intToNsdata:data.length];
            NSString* head = [NSString stringWithFormat:@"%@11",dId];
            
            [_socket writeData:[@"$" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:0];
            [_socket writeData:len withTimeout:-1 tag:0];
            [_socket writeData:[head dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:0];
            [_socket writeData:data withTimeout:-1 tag:0];
        }else
        {
            NSString* head = [NSString stringWithFormat:@"$%04d%@11",data.length,dId];
            [_socket writeData:[head dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:0];
            [_socket writeData:data withTimeout:-1 tag:0];
        }
        
   
    }
    @catch (NSException *exception) {
        NSLog(@" socket error");
    }
    @finally {
        [self.socketLock unlock];
    }
}

-(void)sendNsData:(NSData*) protocolData
{
    
    [_socket writeData:protocolData withTimeout:-1 tag:0];
    // [_socket writeData:protocolData withTimeout:30 tag:REQUEST_TAG];
    
}

- (void)sendProtocol:(SYNProtocol*)synProtocol
{
    //    NSDictionary *req = @{KEY_REQUEST: request,
    //                          KEY_COMPLETE_HANDLER: completeHandler};
    //    [_requests addObject:req];
    
    NSData *requestData = [synProtocol getProtocolData];
    int32_t length = [requestData length];
    length = htonl(length);
    NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(int32_t)];
    
    NSMutableData *data = [[NSMutableData alloc] initWithData:lengthData];
    [data appendData:requestData];
    [_socket writeData:data withTimeout:30 tag:HEADER_TAG];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    
    NSLog(@"Server is connected");
    _isRunning = YES;
    self.connState = 1;
    self.userState = 1;
    [sock performBlock:^{
        [sock enableBackgroundingOnSocket];
    }];
    
    [_socket readDataToLength:10 withTimeout:-1 tag:0];
    
    self.reConnCount=0;
    NSLog([[NSString alloc] initWithFormat:@"%hhd",_reConnflag ]);
    
//    [self sendL99];
    
    if (_reConnflag) {
//        [self sendLOL];
        _reConnflag=NO;
    }
}



- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    
}


- (void)onSocket:(GCDAsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"willDisconnectWithError %@",err);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    NSString *msg = @"socket is closed with error";
    NSLog(@"%@",msg);
    _socket = nil;
    self.connState = -2;

    if (self.reConnCount < 5) {
        [self connectServerAgain];
        self.reConnCount++;
    }
}

- (void)onSocketDidDisconnect:(GCDAsyncSocket *)sock
{
    NSString *msg = @"socket is closed";
    NSLog(@"%@",msg);
    _socket = nil;
    self.connState = -3;
    //[self connectServerAgain];
}

- (void) connectServerAgain
{
    @try
    {
//    if(self.userState != -1 && self.userState != 0)
//    {
        NSLog(@"will reConnecting");
        _reConnflag = YES;
//        [self connectServer];
    
      
    } @catch (NSException *exception) {
        NSLog(@" netsocket  is %@",exception);
    }
  
    
    
//        NSMutableDictionary* L01Dic = [[NSMutableDictionary alloc] init];
//        [L01Dic setObject:myDelegate.stUser.userLoginName forKey:@"loginName"];
//        NSData *l10 = [NSJSONSerialization dataWithJSONObject:l10Dic options:0 error:nil];
//        [self sendId:@"L10" Data:l10];
//    }
}

- (void)onSocketDidSecure:(GCDAsyncSocket *)sock{
    NSString *msg = @"Sorry this connect is sock";
    NSLog(@"%@",msg);
}

-(NSString*) nDataToGbkString:(NSData*)nData
{
    return (__bridge NSString *)CFStringCreateWithBytes(NULL,[nData bytes], [nData length],kCFStringEncodingGB_18030_2000,false);

}

NSMutableData *dataRecv = nil;
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (tag==HEADER_TAG)
    {
        dataRecv = [[NSMutableData alloc] init];
        
        NSData* sData = [data subdataWithRange:NSMakeRange(1, 4)] ;
        
        int iLength = 0;
        if (PROTOCOL_TYPE==1) {
            NSMutableData *smData = [[NSMutableData alloc] initWithData:sData];
            
            unsigned char tmp0 = ((unsigned char*)smData.mutableBytes)[0] ;
            unsigned char tmp1 = ((unsigned char*)smData.mutableBytes)[1] ;
            unsigned char tmp2 = ((unsigned char*)smData.mutableBytes)[2] ;
            unsigned char tmp3 = ((unsigned char*)smData.mutableBytes)[3] ;
            ((unsigned char*)smData.mutableBytes)[3]  = tmp0;
            ((unsigned char*)smData.mutableBytes)[2]  = tmp1;
            ((unsigned char*)smData.mutableBytes)[1]  = tmp2;
            ((unsigned char*)smData.mutableBytes)[0]  = tmp3;
            
            
            
            [smData getBytes: &iLength length: sizeof(iLength)];
        }else
        {
            NSString *sLength = [self nDataToGbkString:sData];
            iLength = [sLength integerValue];
        }
        
        
        
        
        //  NSData* dataLength  = [data subdataWithRange:NSMakeRange(1, 4)] ;
        
        
        @try {
            [dataRecv appendData:data];
        }
        @catch (NSException *exception) {
            NSLog(@" exception is %@",exception);
        }
        @finally {
              [_socket readDataToLength:iLength withTimeout:-1 tag:DATA_TAG];
        }
        
      
    }
    else
    {

        @try {
            [dataRecv appendData:data];
            [SYNDispatchProcessor putProtocol:dataRecv];
        }
        @catch (NSException *exception) {
            NSLog(@" exception is %@",exception);
        }
        @finally {
            [_socket readDataToLength:10 withTimeout:-1 tag:HEADER_TAG];
        }

        
    }
}

- (void)closeSocket
{
    
//    [_socket disconnect];
    [_socket disconnectAfterReadingAndWriting];
}


-(NSData *)intToNsdata:(int)sId
{
    NSMutableData *sIdData = [NSMutableData dataWithBytes: &sId length: sizeof(sId)];
    unsigned char tmp1 = ((unsigned char*)sIdData.mutableBytes)[0] ;
    unsigned char tmp2 = ((unsigned char*)sIdData.mutableBytes)[1] ;
    unsigned char tmp3 = ((unsigned char*)sIdData.mutableBytes)[2] ;
    unsigned char tmp4 = ((unsigned char*)sIdData.mutableBytes)[3] ;
    
    ((unsigned char*)sIdData.mutableBytes)[0] = tmp4;
    ((unsigned char*)sIdData.mutableBytes)[1] = tmp3;
    ((unsigned char*)sIdData.mutableBytes)[2] = tmp2;
    ((unsigned char*)sIdData.mutableBytes)[3] = tmp1;
    return sIdData;
}

-(int)nsdataToint:(NSData*)sData
{
    
    NSMutableData *smData = [[NSMutableData alloc] initWithData:sData];
    
    unsigned char tmp0 = ((unsigned char*)smData.mutableBytes)[0] ;
    unsigned char tmp1 = ((unsigned char*)smData.mutableBytes)[1] ;
    unsigned char tmp2 = ((unsigned char*)smData.mutableBytes)[2] ;
    unsigned char tmp3 = ((unsigned char*)smData.mutableBytes)[3] ;
    ((unsigned char*)smData.mutableBytes)[3]  = tmp0;
    ((unsigned char*)smData.mutableBytes)[2]  = tmp1;
    ((unsigned char*)smData.mutableBytes)[1]  = tmp2;
    ((unsigned char*)smData.mutableBytes)[0]  = tmp3;
    
    
    int iLength = 0;
    [smData getBytes: &iLength length: sizeof(iLength)];
    
    return iLength;
}

- (void)sendL99
{
    if (self.fromId==nil) {
        
        
        self.fromId = [[NSString alloc] initWithFormat:@"%d",abs(arc4random())];;
        NSLog(@"============== %@",self.fromId );
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    dic[@"userId"] = self.fromId;
    NSData *l99Data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    [self sendId:@"L99" Data:l99Data];
}


@end


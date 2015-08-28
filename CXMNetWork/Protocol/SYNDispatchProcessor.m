//
//  SYNDispatchProcessor.m
//  Synectics
//
//  Created by isoftpro on 14-4-20.
//  Copyright (c) 2014年 isoftpro. All rights reserved.
//

#import "SYNDispatchProcessor.h"


static NSMutableArray* protocolmutableArrays ;

@implementation SYNDispatchProcessor

@synthesize _timer;


- (id)init
{
    self = [super init];
    if (self)
    {
        
        if(!protocolmutableArrays)
        {
            protocolmutableArrays = [[NSMutableArray alloc] initWithArray:nil];
        }
        if(!self.arrayLock)
        {
              self.arrayLock = [[NSLock alloc] init];
        }
      
        
    }
    return self;
}

+(void) putProtocol:(NSData*)pData
{
    
    if(!protocolmutableArrays)
    {
      protocolmutableArrays = [[NSMutableArray alloc] initWithArray:nil];
    }
    
    [protocolmutableArrays addObject:pData];
    
}



-(void) delayTimeGCDbuild
{

    NSLog(@"主线程 %@", [NSThread  currentThread]);
    //间隔还是1秒
    uint64_t interval = 1 * NSEC_PER_SEC  / 100 ;
    //创建一个专门执行timer回调的GCD队列
//    dispatch_queue_t queue = dispatch_queue_create("my queue", 0);
     dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建Timer
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //使用dispatch_source_set_timer函数设置timer参数
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0);
    
    //设置回调
    dispatch_source_set_event_handler(_timer, ^()
    {
        [self.arrayLock lock];
        if([protocolmutableArrays count]>0)
        {
            NSData* nData = [protocolmutableArrays objectAtIndex:0];
           // NSLog(@"Hava received datas is----- :%@",[self nDataToGbkString:nData]);
            NSData* d = [nData subdataWithRange:NSMakeRange(5, 3)];
            
            NSString* aStr = [[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding];
            NSLog(@" res %@",aStr);
            //if([aStr isEqualToString:@"L01"])
            {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:aStr object:[nData subdataWithRange:NSMakeRange(10, nData.length-10)]];

            }
            [protocolmutableArrays removeObjectAtIndex:0];
        }
       [self.arrayLock unlock];
        
    });
    //dispatch_source默认是Suspended状态，通过dispatch_resume函数开始它
    dispatch_resume(_timer);
    
}

@end



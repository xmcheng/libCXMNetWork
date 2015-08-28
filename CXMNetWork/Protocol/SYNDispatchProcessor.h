//
//  SYNDispatchProcessor.h
//  Synectics
//
//  Created by isoftpro on 14-4-20.
//  Copyright (c) 2014年 isoftpro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYNProtocol.h"

@interface SYNDispatchProcessor : NSObject

@property dispatch_source_t _timer;
@property NSLock* arrayLock ;
+(void) putProtocol:(NSData*) pData;


-(void) delayTimeGCDbuild;



@end

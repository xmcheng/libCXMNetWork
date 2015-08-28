//
//  SYNProtocol.h
//  Synectics
//
//  Created by isoftpro on 14-4-19.
//  Copyright (c) 2014年 isoftpro. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SYNProtocol : NSObject

@property NSString* version;
@property NSString* id;
@property NSInteger* length;
@property NSInteger* pageCount;
@property NSInteger* pageSize;

//协议数据段
- (NSData*) getProtocolData;

//协议ID
- (NSString*) getProtocoId;

//单包头协议
+ (SYNProtocol*) buildProtocol:(NSString*)protocolId withJsonData:(NSData*) jsonData;
+ (SYNProtocol*) buildProtocol:(NSString*)protocolId withMutableDictionaryData:(NSMutableDictionary *) mutableDictionary;

//双包头协议
+ (SYNProtocol*) buildProtocol:(NSString*)protocolId withServiceId:(NSNumber*) serviceId andForm:(NSString*)from andTo:(NSString*) to withJsonData:(NSData*) jsonData;
+ (SYNProtocol*) buildProtocol:(NSString*)protocolId withServiceId:(NSNumber*) serviceId andForm:(NSString*)from andTo:(NSString*) to withMutableDictionaryData:(NSMutableDictionary *)
mutableDictionary;



@end

//
//  GCTwilioAPIClient.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-10.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "AFHTTPClient.h"

@interface GCTwilioAPIClient : AFHTTPClient

+ (GCTwilioAPIClient *)sharedClient;

- (void)sendSMSMessageWithAttributes:(NSDictionary *)attributes block:(void (^)(NSDictionary *JSON, NSError *error))block;

@end

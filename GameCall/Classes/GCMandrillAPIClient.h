//
//  GCMandrillAPIClient.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-10.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "AFHTTPClient.h"

@interface GCMandrillAPIClient : AFHTTPClient

+ (GCMandrillAPIClient *)sharedClient;

- (void)sendTemplateWithAttributes:(NSDictionary *)attributes block:(void (^)(NSDictionary *response))block;

@end

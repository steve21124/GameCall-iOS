//
//  GCTwitterAPIClient.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-01.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <Twitter/Twitter.h>
#import "AFHTTPClient.h"

extern NSInteger const GCTwitterAPIClientUserLookupMaximum;

@interface GCTwitterAPIClient : AFHTTPClient

+ (GCTwitterAPIClient *)sharedClient;

- (void)verifyCredentialsWithBlock:(void (^)(NSDictionary *credentials, NSError *error))block;
- (void)friendIdsWithCursor:(NSInteger)cursor block:(void (^)(NSArray *ids, NSInteger nextCursor, NSError *error))block;
- (void)lookupUsersWithIds:(NSArray *)ids block:(void (^)(NSArray *users, NSError *error))block;
- (void)updateStatusWithParameters:(NSDictionary *)parameters block:(void (^)(NSDictionary *status, NSError *error))block;

@end

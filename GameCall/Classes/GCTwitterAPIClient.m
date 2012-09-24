//
//  GCTwitterAPIClient.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-01.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCTwitterAPIClient.h"
#import "AFJSONRequestOperation.h"

NSInteger const GCTwitterAPIClientUserLookupMaximum = 100;
static NSString * const kGCTwitterAPIBaseURLString = @"https://api.twitter.com/1/";

@implementation GCTwitterAPIClient

#pragma mark - GCTwitterAPIClient

+ (GCTwitterAPIClient *)sharedClient {
    static GCTwitterAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedClient = [[GCTwitterAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kGCTwitterAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (void)verifyCredentialsWithBlock:(void (^)(NSDictionary *credentials, NSError *error))block {
    NSDictionary *parameters = @{ @"skip_status" : @"true" };
    
    [[GCTwitterAPIClient sharedClient] getPath:@"account/verify_credentials" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *credentials) {
        if (block) {
            block(credentials, nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)friendIdsWithCursor:(NSInteger)cursor block:(void (^)(NSArray *ids, NSInteger nextCursor, NSError *error))block {
    NSDictionary *parameters = @{ @"stringify_ids" : @"true", @"cursor" : @(cursor) };
    
    [[GCTwitterAPIClient sharedClient] getPath:@"friends/ids" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
        if (block) {
            NSArray *ids = [JSON valueForKeyPath:@"ids"];
            NSInteger nextCursor = [[JSON valueForKeyPath:@"next_cursor"] intValue];
            
            block(ids, nextCursor, nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, -1, error);
        }
    }];
}

- (void)lookupUsersWithIds:(NSArray *)ids block:(void (^)(NSArray *users, NSError *error))block {
    ids = [ids subarrayWithRange:NSMakeRange(0, MIN(ids.count, 100))];
    
    NSDictionary *parameters = @{ @"include_entities" : @(NO), @"user_id" : [ids componentsJoinedByString:@","] };
    
    [[GCTwitterAPIClient sharedClient] postPath:@"users/lookup" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSArray *users) {
        if (block) {
            block(users, nil);
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)updateStatusWithParameters:(NSDictionary *)parameters block:(void (^)(NSDictionary *, NSError *))block {
    [[GCTwitterAPIClient sharedClient] postPath:@"statuses/update" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *post) {
        if (block) {
            block(post, nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

#pragma mark - AFHTTPClient

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    
    [[PFTwitterUtils twitter] signRequest:request];
    
    return request;
}

@end

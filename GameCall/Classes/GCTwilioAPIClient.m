//
//  GCTwilioAPIClient.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-10.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCTwilioAPIClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const GCTwilioAPIBaseURLString = @"https://api.twilio.com/2010-04-01/";
static NSString * const GCTwilioAccountSid = @"AC431fe272347f40448ec0b86867a0f6bb";
static NSString * const GCTwilioAuthToken = @"fcb52064f9fb6cbd366741dba094e829";
static NSString * const GCTwilioSandboxNumber = @"+14155992671";
static NSString * const GCTwilioGameCallNumber = @"+16042296287";

@implementation GCTwilioAPIClient

#pragma mark - GCTwilioAPIClient

+ (GCTwilioAPIClient *)sharedClient {
    static GCTwilioAPIClient *_sharedClient;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedClient = [[GCTwilioAPIClient alloc] initWithBaseURL:[NSURL URLWithString:GCTwilioAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (void)sendSMSMessageWithAttributes:(NSDictionary *)attributes block:(void (^)(NSDictionary *JSON, NSError *error))block {
    NSString *body = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ has invited you to join GameCall, the best way to notify your friends with your game plans, or keep up with theirs. http://bit.ly/QlFhod", nil), [attributes objectForKey:@"otherFirstName"], [attributes objectForKey:@"myFirstName"]];
    NSDictionary *parameters = @{ @"From" : GCTwilioGameCallNumber, @"To" : [attributes objectForKey:@"to"], @"Body" : body };
    NSString *path = [NSString stringWithFormat:@"Accounts/%@/SMS/Messages.json", GCTwilioAccountSid];
    
    [[GCTwilioAPIClient sharedClient] postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
        if (block) {
            block(JSON, nil);
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
    [self setAuthorizationHeaderWithUsername:GCTwilioAccountSid password:GCTwilioAuthToken];
    
    return self;
}

@end

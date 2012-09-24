//
//  GCMandrillAPIClient.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-10.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCMandrillAPIClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kGCMandrillAPIBaseURLString = @"https://mandrillapp.com/api/1.0/";
static NSString * const kGCMandrillAPIKey = @"aab5fff5-c4d8-4c4e-bdbc-6f663093f652";
static NSString * const kGCMandrillAPITemplateName = @"app invitation - 2nd option";

@implementation GCMandrillAPIClient

#pragma mark - GCMandrillAPIClient

+ (GCMandrillAPIClient *)sharedClient {
    static GCMandrillAPIClient *_sharedClient;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedClient = [[GCMandrillAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kGCMandrillAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (void)sendTemplateWithAttributes:(NSDictionary *)attributes block:(void (^)(NSDictionary *response))block {        
    NSArray *templateContent = @[
        @{ @"name" : @"from", @"content" : [attributes objectForKey:@"from"] },
        @{ @"name" : @"to", @"content" : [attributes objectForKey:@"to"] }
    ];
    
    NSDictionary *message = @{
        @"subject" : NSLocalizedString(@"You are invited to join GameCall, the best way to notify your friends with your game plans, or keep up with theirs.", nil),
        @"from_email" : [attributes objectForKey:@"from_email"],
        @"from_name" : [attributes objectForKey:@"from_name"],
        @"to" : @[
            @{ @"email" : [attributes objectForKey:@"email"] },
            @{ @"to" : [attributes objectForKey:@"name"] }
        ]
    };

    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:kGCMandrillAPIKey, @"key", kGCMandrillAPITemplateName, @"template_name", templateContent, @"template_content", message, @"message", nil];

    [[GCMandrillAPIClient sharedClient] postPath:@"messages/send-template.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
        if (block) {
            block(JSON);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        TFLog(@"%@", error);
        
        if (block) {
            block(nil);
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
    self.parameterEncoding = AFJSONParameterEncoding;
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

@end

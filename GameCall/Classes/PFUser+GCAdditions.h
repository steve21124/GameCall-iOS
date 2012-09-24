//
//  PFUser+GCAdditions.h
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-04.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "Parse/Parse.h"

@class GCPointAnnotation;

@interface PFUser (GCAdditions)

- (void)friendsWithBlock:(void (^)(NSArray *friends, NSError *error))block;
- (void)addFriend:(PFUser *)friend block:(void (^)(BOOL succeeded, NSError *error))block;
- (void)removeFriend:(PFUser *)friend block:(void (^)(BOOL succeeded, NSError *error))block;

- (void)favoritesWithBlock:(void (^)(NSArray *favorites, NSError *error))block;

- (void)myGamesWithBlock:(void (^)(NSArray *games, NSError *error))block;
- (void)suggestedGamesWithBlock:(void (^)(NSArray *games, NSError *error))block;

- (void)logOutFromGameCall;

@end

//
//  PFUser+GCAdditions.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-04.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "PFUser+GCAdditions.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "GCPointAnnotation.h"

@implementation PFUser (GCAdditions)

- (void)friendsWithBlock:(void (^)(NSArray *friends, NSError *error))block {
    PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
    PFQuery *myFriendsQuery = myFriendsRelation.query;
    
    myFriendsQuery.className = @"_User";
    [myFriendsQuery orderByAscending:@"lastName"];
    
    if (myFriendsQuery.hasCachedResult) {
        myFriendsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [myFriendsQuery findObjectsInBackgroundWithBlock:block];
}

- (void)addFriend:(PFUser *)friend block:(void (^)(BOOL succeeded, NSError *error))block {
    PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
    
    [myFriendsRelation addObject:friend];
    [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            if (block) {
                block(NO, error);
            }
            
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GCFriendAddedNotification object:nil];
        
        if (block) {
            block(YES, nil);
        }
    }];
}

- (void)removeFriend:(PFUser *)friend block:(void (^)(BOOL succeeded, NSError *error))block {
    PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
    
    [myFriendsRelation removeObject:friend];
    [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            if (block) {
                block(NO, error);
            }
            
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GCFriendRemovedNotification object:nil];
        
        if (block) {
            block(YES, nil);
        }
    }];
}

- (void)favoritesWithBlock:(void (^)(NSArray *favorites, NSError *error))block {
    PFRelation *myFavoritesRelation = [[PFUser currentUser] relationforKey:@"favorites"];
    PFQuery *myFavoritesQuery = myFavoritesRelation.query;
    
    myFavoritesQuery.className = @"Venue";
    [myFavoritesQuery orderByAscending:@"name"];
    
    if (myFavoritesQuery.hasCachedResult) {
        myFavoritesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    if (block) {
        [myFavoritesQuery findObjectsInBackgroundWithBlock:block];
    }
}

- (void)myGamesWithBlock:(void (^)(NSArray *games, NSError *error))block {
    PFRelation *myGamesRelation = [[PFUser currentUser] relationforKey:@"games"];
    PFQuery *myGamesQuery = myGamesRelation.query;
    
    myGamesQuery.className = @"Game";
    [myGamesQuery whereKey:@"date" greaterThanOrEqualTo:[NSDate date]];
    [myGamesQuery includeKey:@"parent"];
    [myGamesQuery includeKey:@"venue"];
    [myGamesQuery orderByAscending:@"date"];
    
    if (myGamesQuery.hasCachedResult) {
        myGamesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [myGamesQuery findObjectsInBackgroundWithBlock:block];
}

- (void)suggestedGamesWithBlock:(void (^)(NSArray *games, NSError *error))block {
    PFQuery *friendedByQuery = [PFUser query];
    PFQuery *suggestedGamesQuery = [PFQuery queryWithClassName:@"Game"];
    
    [friendedByQuery whereKey:@"friends" equalTo:[PFUser currentUser]];
    
    if (friendedByQuery.hasCachedResult) {
        friendedByQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [suggestedGamesQuery whereKey:@"players" matchesQuery:friendedByQuery];
    [suggestedGamesQuery whereKey:@"players" notEqualTo:[PFUser currentUser]];
    [suggestedGamesQuery whereKey:@"date" greaterThanOrEqualTo:[NSDate date]];
    [suggestedGamesQuery includeKey:@"parent"];
    [suggestedGamesQuery includeKey:@"venue"];
    [suggestedGamesQuery orderByAscending:@"date"];
    
    if (suggestedGamesQuery.hasCachedResult) {
        suggestedGamesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [suggestedGamesQuery findObjectsInBackgroundWithBlock:block];
}

- (void)logOutFromGameCall {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sports"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"contactsLinkedWithUser"];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [PFPush unsubscribeFromChannelInBackground:[NSString stringWithFormat:@"GC%@", [PFUser currentUser].objectId]];
    [PFUser logOut];
    [(UINavigationController *)appDelegate.window.rootViewController popToRootViewControllerAnimated:YES];
}

@end

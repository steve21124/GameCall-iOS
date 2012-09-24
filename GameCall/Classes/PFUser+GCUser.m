//
//  PFUser+GCUser.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-26.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "PFUser+GCUser.h"

@implementation PFUser (GCUser)

- (void)findFriendsInBackgroundWithBlock:(GCUserFindFriendsBlock)block {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"friends"];
    PFQuery *query = relation.query;
    
    query.className = @"_User";
    [query orderByAscending:@"lastName"];
    
    if (query.hasCachedResult) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query findObjectsInBackgroundWithBlock:block];
}

- (void)addFriend:(PFUser *)friend eventually:(GCUserAddFriendBlock)block {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"friends"];
    
    [relation addObject:friend];
    [[PFUser currentUser] saveEventually:block];
}

- (void)removeFriend:(PFUser *)friend eventually:(GCUserRemoveFriendBlock)block {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"friends"];
    
    [relation removeObject:friend];
    [[PFUser currentUser] saveEventually:block];
}

- (void)findFavoritesInBackgroundWithBlock:(GCUserFindFavoritesBlock)block {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"favorites"];
    PFQuery *query = relation.query;
    
    query.className = @"Venue";
    [query orderByAscending:@"name"];
    
    if (query.hasCachedResult) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query findObjectsInBackgroundWithBlock:block];
}

- (void)addFavorite:(PFObject *)favorite eventually:(GCUserAddFavoriteBlock)block {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"favorites"];
    
    [relation addObject:favorite];
    [[PFUser currentUser] saveEventually:block];
}

- (void)removeFavorite:(PFObject *)favorite eventually:(GCUserRemoveFavoriteBlock)block {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"favorites"];
    
    [relation removeObject:favorite];
    [[PFUser currentUser] saveEventually:block];
}

- (void)findMyGamesInBackgroundWithBlock:(GCUserFindMyGamesBlock)block {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"games"];
    PFQuery *query = relation.query;
    
    query.className = @"Game";
    [query whereKey:@"date" greaterThanOrEqualTo:[NSDate date]];
    [query includeKey:@"parent"];
    [query includeKey:@"venue"];
    [query orderByAscending:@"date"];
    
    if (query.hasCachedResult) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query findObjectsInBackgroundWithBlock:block];
}

- (void)findSuggestedGamesInBackgroundWithBlock:(GCUserFindSuggestedGamesBlock)block {
    PFQuery *friendedByQuery = [PFUser query];
    PFQuery *suggestedGamesQuery = [PFQuery queryWithClassName:@"Game"];
    
    [friendedByQuery whereKey:@"friends" equalTo:[PFUser currentUser]];
    
    if (friendedByQuery.hasCachedResult) {
        friendedByQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [suggestedGamesQuery whereKey:@"players" matchesQuery:friendedByQuery];
    [suggestedGamesQuery whereKey:@"players" notEqualTo:[PFUser currentUser]];
    [suggestedGamesQuery includeKey:@"parent"];
    [suggestedGamesQuery includeKey:@"venue"];
    [suggestedGamesQuery orderByAscending:@"date"];
    
    if (suggestedGamesQuery.hasCachedResult) {
        suggestedGamesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [suggestedGamesQuery findObjectsInBackgroundWithBlock:block];
}

- (void)addGame:(PFObject *)game eventually:(GCUserAddGameBlock)block {
    
}

- (void)removeGame:(PFObject *)game eventually:(GCUserRemoveGameBlock)block {
    
}

@end

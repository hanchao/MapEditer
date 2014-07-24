//
//  Relation.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMRelation.h"

@implementation OSMMember

@end


@implementation OSMRelation


-(id) init {
	if (self!=[super init]) {
		return nil;
	}
	self.members = [NSMutableArray array];
	return self;
}

- (void)addMember:(OSMMember *)member
{
    self.members = [self.members arrayByAddingObject:member];
}

- (void)removeMember:(OSMMember *)member
{
    if([self.members containsObject:member]) {
        NSMutableArray * mutableMembers = [self.members mutableCopy];
        [mutableMembers removeObject:member];
        self.members = [NSArray arrayWithArray:mutableMembers];
    }
}

-(NSString *)tableName
{
    return @"relations";
}
-(NSString *)tagsTableName
{
    return @"relations_tags";
}


@end

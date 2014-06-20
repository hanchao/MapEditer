//
//  Relation.h
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "OSMElement.h"

@interface OSMMember : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic) int64_t ref;
@property (nonatomic, strong) NSString *role;
@property (nonatomic,strong) OSMElement *member;

@end


@interface OSMRelation : OSMElement

@property (nonatomic,strong)NSArray* members;

- (void)addMember:(OSMMember *)member;
- (void)removeMember:(OSMMember *)member;

@end

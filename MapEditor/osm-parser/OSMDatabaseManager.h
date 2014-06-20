//
//  RoadNetworkDAO.h
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
//Uses the sqlite embedded in spatialite and not the platform one.
#import "sqlite3.h"

@class OSMElement;
@class OSMNode;
@class OSMWay;
@class OSMRelation;
@class FMDatabaseQueue;

@protocol OSMDatabaseManagerDelegate <NSObject>

-(void)didFinishSavingNewElements:(NSArray *)newElements updatedElements:(NSArray *)updatedElements;

@end

@interface OSMDatabaseManager : NSObject

@property (readonly) NSString* filePath;

@property (nonatomic, weak)id<OSMDatabaseManagerDelegate> delegate;


//@property (nonatomic,strong)FMDatabase *database;

/** Inits a new OSMDatabaseManager */
- (id)initWithFilePath:(NSString*)filePath;

- (id)initWithDatabaseQueueu:(FMDatabaseQueue *)databaseQueue;

- (id)initWithFilePath:(NSString*)filePath overrideIfExists:(BOOL)override;

/** Stores the given nodes in one single transaction. */
- (void)addNodes:(NSArray*)nodes;

/** Returns a node from its nodeid. */
- (OSMNode*)getNodeFromID:(int64_t)nodeId withTags:(BOOL)withTags;

- (NSArray*)getNodesForWay:(OSMWay*)way;

- (OSMWay*)getWayWithID:(int64_t)wayid;


- (void)addWay:(OSMWay *)way;
- (void)addRelation:(OSMRelation *)rel;

- (void)addWays:(NSArray*)ways;

- (void)deleteWaysWithIds:(NSArray*)waysIds;


- (OSMRelation*)getRelationWithID:(int64_t)relationid;

- (NSDictionary*)getTagsForElement:(OSMElement *)element;
- (NSDictionary*)tagsForWay:(int64_t)wayId;

- (NSArray*)getWaysIdsMembersForRelationWithId:(int64_t)relationId;


+ (NSArray *)sqliteInsertTagsString:(OSMElement *)element;
+ (NSString *)sqliteInsertOrReplaceString:(OSMElement*)element;
+ (NSString *)tableName:(OSMElement *)element;

@end

//
//  Way.h
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "OSMElement.h"

@class OSMNode;

/**
 This class describes a Way as defined in a .osm XML file. 
 */
@interface OSMWay : OSMElement

@property (nonatomic, strong) NSArray *nodes;
@property (nonatomic, strong, readonly) NSArray *nodesIds;

- (void)addNode:(OSMNode *)node;
- (void)addNodeId:(int64_t)nodeId;

- (int64_t)getCommonNodeIdWith:(OSMWay*)way;

/** Returns YES if the given nodeid is the first one of this way. */
- (BOOL)isFirstNodeId:(int64_t)nodeId;

/** Returns YES if the given nodeid is the last one of this way. */
- (BOOL)isLastNodeId:(int64_t)nodeId;

/** Returns the nodeid of the first node of this way. */
- (int64_t)firstNodeId;

/** Returns the nodeid of the last node of this way. */
- (int64_t)lastNodeId;



@end

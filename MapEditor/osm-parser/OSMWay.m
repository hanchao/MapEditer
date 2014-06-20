//
//  Way.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMWay.h"
#import "OSMNode.h"

@interface OSMWay ()

@property (nonatomic, strong) NSArray *nodesIds;


@end

@implementation OSMWay

- (void)addNode:(OSMNode *)node
{
    if(!self.nodes) {
        self.nodes = @[node];
    }
    else {
        self.nodes = [self.nodes arrayByAddingObject:node];
    }
    
    [self addNodeId:node.elementID];
}
- (void)addNodeId:(int64_t)nodeId
{
    if(!self.nodesIds) {
        self.nodesIds = @[[NSNumber numberWithLongLong:nodeId]];
    }
    else {
        self.nodesIds = [self.nodesIds arrayByAddingObject:[NSNumber numberWithLongLong:nodeId]];
    }
}

- (void)setNodes:(NSArray *)nodes {
    _nodes = nodes;
    self.nodesIds = nil;
    
    [_nodes enumerateObjectsUsingBlock:^(OSMNode *node, NSUInteger idx, BOOL *stop) {
        [self addNodeId:node.elementID];
    }];
    
}

-(BOOL) isFirstNodeId:(int64_t)nodeId {
    if (nodeId != 0 || [self.nodesIds count]) {
        return [[self.nodesIds objectAtIndex:0] longLongValue]==nodeId;
    }
    return NO;
}

-(BOOL) isLastNodeId:(int64_t)nodeId {
    if (nodeId != 0 || [self.nodesIds count]) {
        return [[self.nodesIds objectAtIndex:[self.nodesIds count]-1] longLongValue]==nodeId;
    }
    return  NO;
}

-(int64_t) lastNodeId {
	if ([self.nodesIds count]==0)
		return 0;
	else
		return [[self.nodesIds objectAtIndex:[self.nodesIds count]-1] longLongValue];
}

-(int64_t) firstNodeId {
	if ([self.nodesIds count]==0)
		return 0;
	else
		return [[self.nodesIds objectAtIndex:0] longLongValue];
}

-(int64_t)getCommonNodeIdWith:(OSMWay*)way {
	int64_t commonNodeId = -1;
	if ([way.self.nodesIds count]==0 || [self.self.nodesIds count]==0)
		return commonNodeId;
	int64_t selfStartNode = [[self.self.nodesIds objectAtIndex:0] longLongValue];
	int64_t selfEndNode = [[self.self.nodesIds objectAtIndex:[self.self.nodesIds count]-1]longLongValue];
	int64_t wayStartNode = [[way.self.nodesIds objectAtIndex:0]intValue];
	int64_t wayEndNode = [[way.self.nodesIds objectAtIndex:[way.self.nodesIds count]-1] longLongValue];
	if (selfStartNode==wayStartNode || selfStartNode==wayEndNode)
		commonNodeId= selfStartNode;
	else if (selfEndNode == wayStartNode || selfEndNode == wayEndNode)
		commonNodeId= selfEndNode;
	return commonNodeId;
}

-(NSString*) description {
	return [NSString stringWithFormat:@"Way(%lli)%lu nodes", self.elementID, (unsigned long)[self.nodesIds count]];
}

-(NSString *)tableName;
{
    return @"ways";
}
-(NSString *)tagsTableName
{
    return @"ways_tags";
}

@end

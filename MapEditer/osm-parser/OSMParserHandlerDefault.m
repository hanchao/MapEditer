//
//  OSMParserHandlerDefault.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMParserHandlerDefault.h"

#import "DDLog.h"
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
static const BOOL OPELogDatabaseErrors = YES;
static const BOOL OPETraceDatabaseTraceExecution = NO;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
static const BOOL OPELogDatabaseErrors = NO;
static const BOOL OPETraceDatabaseTraceExecution = NO;
#endif

@interface OSMParserHandlerDefault ()

/** The total number of parsed nodes. */
@property (nonatomic) NSUInteger nodesCounter;
/** The total number of parsed ways. */
@property (nonatomic) NSUInteger waysCounter;
/** Nodes memory storage before DB flush in one single transaction. */
@property (nonatomic) NSUInteger relationsCounter;

@property (nonatomic, strong) NSMutableArray *nodesBuffer;
/** Ways memory storage before DB flush in one single transaction. */
@property (nonatomic, strong) NSMutableArray *waysBuffer;

@property (nonatomic, strong) NSMutableArray *relationsBuffer;

@property (nonatomic) dispatch_queue_t isolationQueue;

- (BOOL)checkForNodesFlush;
- (BOOL)checkForWaysFlush;
- (BOOL)checkForRelationsFlush;


@end


@implementation OSMParserHandlerDefault

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue
{
    if (self=[super init]) {
        self.databaseManager = [[OSMDatabaseManager alloc] initWithDatabaseQueueu:databaseQueue];
        self.nodesBuffer = [NSMutableArray array];
        self.waysBuffer = [NSMutableArray array];
        self.relationsBuffer = [NSMutableArray array];
        NSString * queueLabel = [NSString stringWithFormat:@"%@.isolation.%@",[self class],self];
        self.isolationQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.bufferMaxSize=30000;
        self.optimizeOnFinished = YES;
        
        self.nodesCounter = 0;
        self.waysCounter = 0;
        self.relationsCounter = 0;
    }
	
	return self;
}

-(id) initWithOutputFilePath:(NSString*)output {
	return [self initWithOutputFilePath:output overrideIfExists:YES];
}

-(id) initWithOutputFilePath:(NSString*)filePath overrideIfExists:(BOOL)override {
	if (self=[super init]) {
        self.databaseManager = [[OSMDatabaseManager alloc] initWithFilePath:filePath overrideIfExists:override];
        self.nodesBuffer = [NSMutableArray array];
        self.waysBuffer = [NSMutableArray array];
        self.relationsBuffer = [NSMutableArray array];
        NSString * queueLabel = [NSString stringWithFormat:@"%@.isolation.%@",[self class],self];
        self.isolationQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.bufferMaxSize=30000;
        self.optimizeOnFinished = YES;
        
        self.nodesCounter = 0;
        self.waysCounter = 0;
        self.relationsCounter = 0;
    }
	
	return self;
}

#pragma mark -
#pragma mark Parser delegate
-(void) didStartParsingNodes {
	DDLogInfo(@"[NOW PARSING NODES]");
}
-(void) didStartParsingWays {
	[self checkForNodesFlush];
	DDLogInfo(@"[NOW PARSING WAYS]");
}
-(void) didStartParsingRelations {
	[self checkForWaysFlush];
	DDLogInfo(@"[NOW PARSING RELATIONS]");
}

- (void)parsingWillStart {
    DDLogInfo(@"[PARSING WILL START]");
}

- (void)parsingDidEnd {
    [self checkForRelationsFlush];
    DDLogInfo(@"[PARSING DID END");
}

-(void) onNodeFound:(OSMNode *)node {
	if (!self.ignoreNodes) {
		//[roadNetwork addNodes:[NSArray arrayWithObject:node]];
		[self.nodesBuffer addObject:node];
		//if (node.tags) 
		//	NSLog(@"this node has tags : %@", node.tags);
		self.nodesCounter++;
		if (self.nodesCounter%self.bufferMaxSize==0) {
			[self checkForNodesFlush];
		}
	}
}

-(void) onWayFound:(OSMWay *)way {
	[self.waysBuffer addObject:way];
	if (![way.nodesIds count]) {
		DDLogWarn(@"WARNING No Node for WAY %lldi", way.elementID);
    }
	self.waysCounter++;
	if (self.waysCounter%(self.bufferMaxSize/20)==0) {
		[self checkForWaysFlush];
	}
}

-(void) onRelationFound:(OSMRelation *)relation {
	//NSLog(@"relation found");
    
	[self.databaseManager addRelation:relation];
}

-(BOOL) checkForNodesFlush {
	if (self.nodesBuffer.count) {
		DDLogInfo(@"parsed %lu nodes", (unsigned long)self.nodesCounter);
		[self.databaseManager addNodes:self.nodesBuffer];
		[self.nodesBuffer removeAllObjects];
		return YES;
	} else {
		return NO;
	}
}

-(BOOL) checkForWaysFlush {
	if ([self.waysBuffer count]) {
		DDLogInfo(@"parsed %lu ways", (unsigned long)self.waysCounter);
		
		[self.databaseManager addWays:self.waysBuffer];
		DDLogInfo(@"Flush !");
		[self.waysBuffer removeAllObjects];
		return YES;
	}else {
		return NO;
	}
}

- (BOOL)checkForRelationsFlush {
    if([self.relationsBuffer count]) {
        
        for(OSMRelation * relation in self.relationsBuffer) {
            [self.databaseManager addRelation:relation];
        }
        [self.relationsBuffer removeAllObjects];
        return YES;
    }
    return NO;
}

@end

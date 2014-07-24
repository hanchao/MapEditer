//
//  OSMParserHandlerDefault.h
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSMParser.h"
#import "OSMDatabaseManager.h"

/**
 The default OSMParser handler.
 It stores any parsed node, way, relation to a spatialite db. Such DB is accessed
 through the OSMDatabaseManager instance given at init time.
 The flush to the DB is done once the limit number of parsed objects has been reached
 (see bufferMaxSize) to limit the number of db transactions and improve db access time. 
 */
@interface OSMParserHandlerDefault : NSObject <OSMParserDelegate>

@property(nonatomic) BOOL ignoreNodes;

/** Configurable number of objects to be put in memory before being flushed to the DB. 
  Default is 30 000 for nodes, and 30 000/20 for ways. */ 
@property(nonatomic) NSUInteger bufferMaxSize;

@property(nonatomic) BOOL optimizeOnFinished;

@property(nonatomic, strong) OSMDatabaseManager * databaseManager;

/**
 Creates a new OSMParserHandlerDefault that will create a spatialite DB at the given output path
 */
- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue;

/**
 Creates a new OSMParserHandlerDefault that will create a spatialite DB at the given output path, 
 overriding the existing file or not.
 */
-(id) initWithOutputFilePath:(NSString*)filePath overrideIfExists:(BOOL)override;

@end

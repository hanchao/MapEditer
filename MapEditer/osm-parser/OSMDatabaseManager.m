//
//  RoadNetworkDAO.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMDatabaseManager.h"
//#import <CoreLocation/CoreLocation.h>
#import "OSMNode.h"
#import "OSMWay.h"
#import "OSMRelation.h"

#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseQueue.h"
//#import "GeoTools.h"
//#import "spatialite.h"



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


@interface OSMDatabaseManager ()

@property (nonatomic,strong) NSString *filePath;
@property (nonatomic,strong) FMDatabaseQueue * databaseQueue;

-(void) initDB;

@end

@implementation OSMDatabaseManager

+(void) initialize {
	//spatialite_init(1);
	//[self createGeometryForWayId:1];
}

- (id)initWithDatabaseQueueu:(FMDatabaseQueue *)databaseQueue
{
    if(self = [self initWithFilePath:databaseQueue.path]) {
        self.databaseQueue = databaseQueue;
    }
    return self;
}

-(id) initWithFilePath:(NSString*)resPath overrideIfExists:(BOOL)override {
	if (self=[super init])
    {
        self.filePath = resPath;
        
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:resPath];
        if (exists && override) {
            NSError * error = nil;
            BOOL sucess = [[NSFileManager defaultManager] removeItemAtPath:resPath error:&error];
            if (!sucess) {
                DDLogError(@"Error removing file - %@",error);
            }
        }
        
        if (!exists || (exists && override)) {
            [self initDB];
        }
    }
	   
   	return self;
}

- (FMDatabaseQueue *)databaseQueue
{
    if (!_databaseQueue){
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    }
    return _databaseQueue;
}

-(id) initWithFilePath:(NSString*)resPath {
	return [self initWithFilePath:resPath overrideIfExists:NO];
}

-(void) dealloc {
	_delegate = nil;
}

-(void) initDB {
    sqlite3 *dbHandle;
    int ret = sqlite3_open_v2 ([self.filePath cStringUsingEncoding:NSUTF8StringEncoding], &dbHandle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
	if (ret != SQLITE_OK) {
        DDLogError(@"error when opening %@", self.filePath);
    }
    else {
        DDLogInfo(@"OPEN OK");
    }
    
    NSString* p = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"roadNetworkInit.sql"];
	DDLogVerbose(@"Path %@", p);
	NSString* initScript = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil];
	DDLogVerbose(@"init script %@", initScript);
	char* errMsg = NULL;
	const char *sql = [initScript cStringUsingEncoding:NSUTF8StringEncoding];
	int returnValue = sqlite3_exec(dbHandle, sql, NULL, NULL, &errMsg);
	if (returnValue!=SQLITE_OK)
    {
        NSAssert1(0, @"Error initializing DB. '%s'", sqlite3_errmsg(dbHandle));
    }
		
    
    close(dbHandle);
    
}

-(NSString *)sqliteCurrentVersionString:(OSMElement *)element
{
    return [NSString stringWithFormat:@"select version from %@ where id = %lld",[OSMDatabaseManager tableName:element],element.elementID];
}

#pragma mark -
#pragma mark Nodes operations

-(void) addNodes:(NSArray*)nodes {
    
    __block NSMutableArray * newNodes = [NSMutableArray array];
    __block NSMutableArray * updateNodes = [NSMutableArray array];
    
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [nodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            OSMNode * node = obj;
            BOOL shouldUpdate = YES;
            BOOL alreadyExists = NO;
            FMResultSet * set = [db executeQuery:[self sqliteCurrentVersionString:node]];
            if ([set next]) {
                int64_t currentVersion = [set longForColumn:@"version"];
                alreadyExists = (currentVersion > 0);
                shouldUpdate = (currentVersion < node.version);
            }
            [set close];
            
            if (shouldUpdate) {
                BOOL success = [db executeUpdate:[OSMDatabaseManager sqliteInsertOrReplaceString:node]];
                if (success) {
                    [db executeUpdate:@"DELETE FROM nodes_tags WHERE node_id = ?",[NSNumber numberWithLongLong:node.elementID]];
                    for(NSString * osmKey in node.tags)
                    {
                        [db executeUpdate:@"insert or replace into nodes_tags(node_id,key,value) values(?,?,?)",[NSNumber numberWithLongLong:node.elementID],osmKey,node.tags[osmKey]];
                    }
                }
                if (alreadyExists) {
                    [updateNodes addObject:node];
                }
                else if(node)
                {
                    [newNodes addObject:node];
                }
            }
        }];
    }];
    
    if ([self.delegate respondsToSelector:@selector(didFinishSavingNewElements:updatedElements:)]) {
        [self.delegate didFinishSavingNewElements:newNodes updatedElements:updateNodes];
    }
}

+(NSString *)sqliteInsertOrReplaceString:(OSMElement*)element
{
    if ([element isKindOfClass:[OSMNode class]]) {
        OSMNode * node = (OSMNode *)element;
        return [NSString stringWithFormat:@"insert or replace into %@(id,latitude,longitude,user,uid,changeset,version,timestamp) values (%lld,%f,%f,\'%@\',%lld,%lld,%lld,\'%@\')",node.tableName,node.elementID,node.latitude,node.longitude,node.user,node.uid,node.changeset,node.version,[node formattedDate]];
    }
    else{
        return [NSString stringWithFormat:@"insert or replace into %@(id,user,uid,changeset,version,timestamp) values (%lld,\'%@\',%lld,%lld,%lld,\'%@\')",element.tableName,element.elementID,element.user,element.uid,element.changeset,element.version,[element formattedDate]];
    }
    
    
}
+(NSArray *)sqliteInsertTagsString:(OSMElement *)element
{
    NSMutableArray * sqlStringArray = [NSMutableArray array];
    if ([element.tags count]) {
        NSString * columnID = [NSString stringWithFormat:@"%@_id",[element.tableName substringToIndex:[element.tableName length] - 1]];
        for (NSString * key in element.tags)
        {
            NSString *sqlString = [NSString stringWithFormat:@"insert or replace into %@(%@,key,value) values(%lld,\'%@\',\'%@\')",element.tableName,columnID,element.elementID,key,element.tags[key]];
            [sqlStringArray addObject:sqlString];
        }
    }
    return sqlStringArray;
    
}

-(OSMNode*) getNodeFromID:(int64_t)nodeId withTags:(BOOL)withTags{
    
    __block OSMNode * node = nil;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * result = [db executeQueryWithFormat:@"SELECT * FROM nodes where id=%lld limit 1",nodeId];
        if ([result next]) {
            node = [[OSMNode alloc] init];
            node.elementID = [result longLongIntForColumn:@"id"];
            node.user = [result stringForColumn:@"user"];
            node.uid = [result longLongIntForColumn:@"uid"];
            node.version = [result longLongIntForColumn:@"version"];
            node.changeset = [result stringForColumn:@"changeset"];
            [node addDateWithString:[result stringForColumn:@"timestamp"]];
            node.latitude = [result doubleForColumn:@"latitude"];
            node.longitude = [result doubleForColumn:@"longitude"];
            node.action = [result stringForColumn:@"action"];
            
            if (withTags) {
                node.tags = [[self getTagsForElement:node] mutableCopy];
            }
        }
        [result close];
    }];
    
    return node;
    
}

+(NSString *)tableName:(OSMElement *)element
{
    NSString * tableName = @"";
    if ([element isKindOfClass:[OSMNode class]]) {
        tableName = @"nodes";
    }
    else if ([element isKindOfClass:[OSMWay class]])
    {
        tableName = @"ways";
    }
    else if ([element isKindOfClass:[OSMRelation class]])
    {
        tableName = @"relations";
    }
    return tableName;
    
}

-(NSDictionary *)getTagsForElement:(OSMElement *)element
{
    __block NSMutableDictionary * tags = [NSMutableDictionary dictionary];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * tableName = @"";
        NSString * idColumnName = @"";
        if ([element isKindOfClass:[OSMNode class]]) {
            tableName = @"nodes_tags";
            idColumnName = @"node_id";
        }
        else if ([element isKindOfClass:[OSMWay class]])
        {
            tableName = @"ways_tags";
            idColumnName = @"way_id";
        }
        else if ([element isKindOfClass:[OSMRelation class]])
        {
            tableName = @"relations_tags";
            idColumnName = @"relation_id";
        }
        
        FMResultSet * results = [db executeQueryWithFormat:@"select key, value from %@ where %@=%lld",tableName,idColumnName,element.elementID];
        while ([results next]) {
            [tags setObject:[results stringForColumn:@"value"] forKey:[results stringForColumn:@"key"]];
        }
    }];
    
    
    return tags;
    
}

-(NSArray*) getNodesForWay:(OSMWay*)way {
	NSMutableArray* nodes = [NSMutableArray arrayWithCapacity:[way.nodes count]];
	for (int i=0; i<[way.nodesIds count]; i++)  {
		int64_t nodeId = [[way.nodesIds objectAtIndex:i] longLongValue];
		OSMNode* n = [self getNodeFromID:nodeId withTags:NO];
		if (n!=nil)
			[nodes addObject:n];
		else
			DDLogWarn(@"Cannot find node %lld for WAY ID %lli tags:%@", nodeId, way.elementID, way.tags);

	}
	return nodes;
}

#pragma mark -
#pragma mark Ways Operations

-(void) deleteWaysWithIds:(NSArray*)waysIds {
	__block NSString* waysIdsSql = @"";
    
    [waysIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        waysIdsSql = [waysIdsSql stringByAppendingFormat:@"%@%@", obj, (idx<[waysIds count]-1)?@",":@""];
    }];
	
    
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeQuery:@"DELETE from ways where wayid IN (?)",waysIdsSql];
    }];
}

-(OSMWay*) getWayWithID:(int64_t)wayid {
	DDLogVerbose(@"geting way %lli", wayid);
	OSMWay* way = [[OSMWay alloc] init];
	way.elementID=wayid;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:@"SELECT nodeid from ways_nodes where wayid=? ORDER BY rowid",wayid];
        
        while ([resultSet next]) {
            int64_t nodeId = [resultSet longLongIntForColumnIndex:0];
            [way addNodeId:nodeId];
        }
        [resultSet close];
        
    }];
    
	return way;
}

- (void)addWay:(OSMWay *)way
{
    [self addWays:@[way]];
}

- (void)addWays:(NSArray*)ways {
    
    __block NSMutableArray * newWays = [NSMutableArray array];
    __block NSMutableArray * updateWays = [NSMutableArray array];
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.logsErrors = OPELogDatabaseErrors;
        db.traceExecution = OPETraceDatabaseTraceExecution;
        __block BOOL success = NO;
       
        for (OSMWay * way in ways) {
            BOOL shouldUpdate = YES;
            BOOL alreadyExists = NO;
            FMResultSet * set = [db executeQuery:[self sqliteCurrentVersionString:way]];
            if ([set next]) {
                int64_t currentVersion = [set longForColumn:@"version"];
                alreadyExists = (currentVersion > 0);
                shouldUpdate = (currentVersion < way.version);
            }
            [set close];
            
            if (shouldUpdate) {
                success = [db executeUpdate:[OSMDatabaseManager sqliteInsertOrReplaceWayString:way]];
                if (success) {
                    [db executeUpdate:@"DELETE FROM ways_nodes WHERE way_id = ?",[NSNumber numberWithLongLong:way.elementID]];
                    [db executeUpdate:@"DELETE FROM ways_tags WHERE way_id = ?",[NSNumber numberWithLongLong:way.elementID]];
                    //NSArray * sql = [OSMDatabaseManager sqliteInsertOrReplaceWayNodesString:way];
                    
                    [way.nodesIds enumerateObjectsUsingBlock:^(NSNumber *nodeId, NSUInteger idx, BOOL *stop) {
                        success = [db executeUpdate:@"INSERT OR REPLACE INTO ways_nodes(way_id,node_id,local_order) values(?,?,?)",[NSNumber numberWithLongLong:way.elementID],nodeId,[NSNumber numberWithUnsignedInteger:idx]];
                        
                    }];
                    
                    
                    for(NSString * osmKey in way.tags)
                    {
                        [db executeUpdate:@"INSERT OR REPLACE INTO ways_tags(way_id,key,value) values(?,?,?)",[NSNumber numberWithLongLong:way.elementID],osmKey,way.tags[osmKey]];
                    }
                    
                    if (alreadyExists) {
                        [updateWays addObject:way];
                    }
                    else
                    {
                        [newWays addObject: way];
                    }
                }
            }
        }
    }];
	
    if ([self.delegate respondsToSelector:@selector(didFinishSavingNewElements:updatedElements:)]) {
        [self.delegate didFinishSavingNewElements:newWays updatedElements:updateWays];
    }
}

/*
 LINESTRING(756881.706704 4850692.62625,
 760361.595005 4852743.267975,
 759582.880944 4855493.610807,
 757549.382306 4855414.551183,
 755734.189332 4856112.118807,
 755020.910885 4855996.887913,
 754824.031873 4854723.577451,
 756021.000385 4850937.420842,
 756881.706704 4850692.62625)
 */
+(NSString *)sqliteInsertOrReplaceWayString:(OSMWay*)way
{
    return [NSString stringWithFormat:@"INSERT OR REPLACE INTO ways(id,user,uid,changeset,version,timestamp) values (%lld,\'%@\',%lld,%lld,%lld,\'%@\')",way.elementID,way.user,way.uid,way.changeset,way.version,[way formattedDate]];
}

#pragma mark -
#pragma mark Relation Operations

-(void) addRelation:(OSMRelation*) rel {
	
	__block BOOL alreadyExists = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.logsErrors = OPELogDatabaseErrors;
        db.traceExecution = OPETraceDatabaseTraceExecution;
        
        BOOL shouldUpdate = YES;
        
        FMResultSet * set = [db executeQuery:[self sqliteCurrentVersionString:rel]];
        if ([set next]) {
            int64_t currentVersion = [set longForColumn:@"version"];
            alreadyExists = (currentVersion > 0);
            shouldUpdate = (currentVersion < rel.version);
        }
        [set close];
        if (shouldUpdate) {
            BOOL insertOK = [db executeUpdate:[OSMDatabaseManager sqliteInsertOrReplaceRelationString:rel]];
            
            if (insertOK) {
                [db executeUpdate:@"DELETE FROM relations_members WHERE relation_id = ?",[NSNumber numberWithLongLong:rel.elementID]];
                [db executeUpdate:@"DELETE FROM relations_tags WHERE relation_id = ?",[NSNumber numberWithLongLong:rel.elementID]];
                
                for (int i=0; i<[rel.members count]; i++) {     
                    OSMMember* m = (OSMMember*)[rel.members objectAtIndex:i];
                    [db executeUpdate:@"insert or replace into relations_members(relation_id,type,ref,role,local_order) values (?,?,?,?,?)",[NSNumber numberWithLongLong:rel.elementID],m.type,[NSNumber numberWithLongLong:m.ref],m.role,[NSNumber numberWithInt:i]];
                    
                }
                if ([rel.tags count]) {
                    
                    for(NSString * osmKey in rel.tags)
                    {
                        [db executeUpdate:@"insert or replace into relations_tags(relation_id,key,value) values(?,?,?)",[NSNumber numberWithLongLong:rel.elementID],osmKey,rel.tags[osmKey]];
                    }
                }
            }
        }
    }];
    
    
    if ([self.delegate respondsToSelector:@selector(didFinishSavingNewElements:updatedElements:)]) {
        if (alreadyExists) {
            [self.delegate didFinishSavingNewElements:nil updatedElements:@[rel]];
        }
        else{
            [self.delegate didFinishSavingNewElements:@[rel] updatedElements:nil];
        }
    }
}

+(NSString *) sqliteInsertOrReplaceRelationString:(OSMRelation *)relation
{
    return [NSString stringWithFormat:@"insert or replace into relations(id,user,uid,changeset,version,timestamp) values (%lld,\'%@\',%lld,%lld,%lld,\'%@\')",relation.elementID,relation.user,relation.uid,relation.changeset,relation.version,[relation formattedDate]];
}

-(NSArray*) getWaysIdsMembersForRelationWithId:(int64_t)relationId {
    
    __block NSMutableArray* membersIds = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *resultSet = [db executeQuery:@"select ref from relations_members where type='way' AND relationid=?",relationId];
        
        while ([resultSet next]) {
            int64_t memberId = [resultSet longLongIntForColumnIndex:0];
            [membersIds addObject:@(memberId)];
        }
        [resultSet close];
    }];
    
    return membersIds;
}

-(NSDictionary *)tagsForWay:(int64_t)wayId
{
    OSMWay * way = [[OSMWay alloc] init];
    way.elementID = wayId;
    return [self getTagsForElement:way];
}

-(OSMRelation*) getRelationWithID:(int64_t) relationid {
	OSMRelation* relation = [[OSMRelation alloc] init];
	relation.elementID=relationid;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * resultSet = [db executeQuery:@"SELECT * FROM relations_members WHERE relationid=? ORDER BY rowid",relationid];
        
        while ([resultSet next]) {
            OSMMember *member = [[OSMMember alloc] init];
            member.ref = [resultSet longLongIntForColumn:@"ref"];
            member.type = [resultSet stringForColumn:@"type"];
            member.role = [resultSet stringForColumn:@"role"];
            
            [relation addMember:member];
        }
    }];
    
	return relation;
		
}


@end

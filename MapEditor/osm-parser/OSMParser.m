//
//  OSMParser.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMParser.h"

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

@interface OSMParser ()

@property (nonatomic, strong) TBXML *parser;
@property (nonatomic, strong) NSOperationQueue *tagOperationQueue;
@property (nonatomic, strong) NSMutableDictionary *tags;
@property (nonatomic) BOOL isFirstNode;
@property (nonatomic) BOOL isFirstWay;
@property (nonatomic) BOOL isFirstRelation;

@end

@implementation OSMParser

-(id)init {
    if (self = [super init]) {
        self.tagOperationQueue = [[NSOperationQueue alloc] init];
        self.tagOperationQueue.maxConcurrentOperationCount = 4;
        self.isFirstNode=YES;
        self.isFirstWay=YES;
        self.isFirstRelation=YES;
        
    }
    return self;
}

- (id)initWithOSMFile:(NSString*)osmFilePath {
    NSData* data = [NSData dataWithContentsOfFile:osmFilePath];
    return [self initWithOSMData:data];
}

-(id)initWithOSMData:(NSData *)data
{
    if (self=[self init]) {
		self.parser=[[TBXML alloc] initWithXMLData:data];
	}
	return self;
}

-(void) parseWithCompletionBlock:(void (^)(void))completionBlock {
    if ([self.delegate respondsToSelector:@selector(parsingWillStart)]){
        [self.delegate parsingWillStart];
    }
    
    NSDate * start = [NSDate date];
    __block double totalNodeTime = 0;
    __block double totalWayTime = 0;
    __block double totalRelationTime = 0;
    __block NSInteger numNodes = 0;
    __block NSInteger numWays = 0;
	TBXMLElement * root = self.parser.rootXMLElement;
    if(root)
    {
        
        NSOperationQueue * operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = 1;
        
        __block NSDate * nodeStart = nil;
        NSBlockOperation * nodeBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            if ([self.delegate respondsToSelector:@selector(didStartParsingNodes)]) {
                [self.delegate didStartParsingNodes];
            }
            nodeStart = [NSDate date];
            numNodes = [self findAllNodes];
        }];
        
        if (ddLogLevel == LOG_LEVEL_VERBOSE) {
            [nodeBlockOperation setCompletionBlock:^{
                totalNodeTime -= [nodeStart timeIntervalSinceNow];
            }];
        }
        
        
        __block NSDate * wayStart = nil;
        NSBlockOperation * wayBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            if ([self.delegate respondsToSelector:@selector(didStartParsingWays)]) {
                [self.delegate didStartParsingWays];
            }
            wayStart = [NSDate date];
            numWays = [self findAllWays];
        }];
        
        if (ddLogLevel == LOG_LEVEL_VERBOSE) {
            [wayBlockOperation setCompletionBlock:^{
                totalWayTime -= [wayStart timeIntervalSinceNow];
            }];
        }
        
        
        __block NSDate * relationStart = nil;
        NSBlockOperation * relationBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            if ([self.delegate respondsToSelector:@selector(didStartParsingRelations)]) {
                [self.delegate didStartParsingRelations];
            }
            relationStart = [NSDate date];
            numWays = [self findAllRelations];
        }];
        
        if (ddLogLevel == LOG_LEVEL_VERBOSE) {
            [relationBlockOperation setCompletionBlock:^{
                totalRelationTime -= [relationStart timeIntervalSinceNow];
            }];
        }
        
        
        NSBlockOperation * endBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            if ([self.delegate respondsToSelector:@selector(parsingDidEnd)])
            {
                [self.delegate parsingDidEnd];
            }
            if (completionBlock) {
                completionBlock();
            }
            
            NSTimeInterval time = [start timeIntervalSinceNow];
            DDLogInfo(@"Total Time: %f",-1*time);
            DDLogInfo(@"Node Time: %f - %f",totalNodeTime,totalNodeTime/numNodes);
            DDLogInfo(@"Way Time: %f - %f",totalWayTime,totalWayTime/numWays);
            DDLogInfo(@"Relation Time: %f",totalRelationTime);
        }];
        
        [endBlockOperation addDependency:nodeBlockOperation];
        [endBlockOperation addDependency:wayBlockOperation];
        [endBlockOperation addDependency:relationBlockOperation];
        
        [operationQueue addOperation:nodeBlockOperation];
        [operationQueue addOperation:wayBlockOperation];
        [operationQueue addOperation:relationBlockOperation];
        [operationQueue addOperation:endBlockOperation];
    }
}

-(NSInteger)findAllNodes
{
    
    NSInteger numberOfNodes = 0;
    TBXMLElement * nodeXML = [TBXML childElementNamed:@"node" parentElement:self.parser.rootXMLElement];
    while (nodeXML) {
        numberOfNodes +=1;
        //int64_t newVersion = [[TBXML valueOfAttributeNamed:@"version" forElement:nodeXML] longLongValue];
        double lat = [[TBXML valueOfAttributeNamed:@"lat" forElement:nodeXML] doubleValue];
        double lon = [[TBXML valueOfAttributeNamed:@"lon" forElement:nodeXML] doubleValue];
        
        OSMNode* node = [[OSMNode alloc] init];
        [node addMetaData:[self attributesWithTBXML:nodeXML]];
		node.latitude = lat;
		node.longitude = lon;
        
        NSBlockOperation * tagBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self findTagsForElement:node withXML:nodeXML];
            [self.delegate onNodeFound:node];
        }];
        
        [self.tagOperationQueue addOperation:tagBlockOperation];
        
        
        nodeXML = [TBXML nextSiblingNamed:@"node" searchFromElement:nodeXML];
    }
    return numberOfNodes;
    
}
-(NSInteger)findAllWays
{
    
    NSInteger numberOfWays = 0;
    TBXMLElement * wayXML = [TBXML childElementNamed:@"way" parentElement:self.parser.rootXMLElement];
    while (wayXML) {
        numberOfWays +=1;
        //int64_t newVersion = [[TBXML valueOfAttributeNamed:@"version" forElement:wayXML] longLongValue];
        //int64_t osmID = [[TBXML valueOfAttributeNamed:@"id" forElement:wayXML] longLongValue];
        
        OSMWay * way = [[OSMWay alloc] init];
        [way addMetaData:[self attributesWithTBXML:wayXML]];
        
        NSBlockOperation * tagBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self findTagsForElement:way withXML:wayXML];
        }];
        
        NSBlockOperation * nodeBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self findNodes:wayXML withWay:way];
            [self.delegate onWayFound:way];
        }];
        
        [nodeBlockOperation addDependency:tagBlockOperation];
        
        [self.tagOperationQueue addOperation:tagBlockOperation];
        [self.tagOperationQueue addOperation:nodeBlockOperation];
        
        
        
        //newWay.isNoNameStreetValue = [newWay noNameStreet];
        
        wayXML = [TBXML nextSiblingNamed:@"way" searchFromElement:wayXML];
    }
    return numberOfWays;
    
}
-(NSInteger)findAllRelations
{
    
    
    NSInteger numberOfRelations = 0;
    TBXMLElement * relationXML = [TBXML childElementNamed:@"relation" parentElement:self.parser.rootXMLElement];
    
    while (relationXML) {
        numberOfRelations +=1;
        OSMRelation * relation = [[OSMRelation alloc] init];
        [relation addMetaData:[self attributesWithTBXML:relationXML]];
        
        NSBlockOperation * tagBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self findTagsForElement:relation withXML:relationXML];
        }];
        
        NSBlockOperation * nodeBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self findMemebers:relationXML withRelation:relation];
            [self.delegate onRelationFound:relation];
        }];
        
        [nodeBlockOperation addDependency:tagBlockOperation];
        
        [self.tagOperationQueue addOperation:tagBlockOperation];
        [self.tagOperationQueue addOperation:nodeBlockOperation];
        
        relationXML = [TBXML nextSiblingNamed:@"relation" searchFromElement:relationXML];
        
    }
    return numberOfRelations;
    
}

-(void)findTagsForElement:(OSMElement*)element withXML:(TBXMLElement *)xmlElement
{
    TBXMLElement* tag = [TBXML childElementNamed:@"tag" parentElement:xmlElement];
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    while (tag) //Takes in tags and adds them to newNode
    {
        NSString* key = [TBXML valueOfAttributeNamed:@"k" forElement:tag];
        NSString* value = [[TBXML valueOfAttributeNamed:@"v" forElement:tag] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        
        [dictionary setObject:value forKey:key];
        tag = [TBXML nextSiblingNamed:@"tag" searchFromElement:tag];
    }
    
    if (element) {
        element.tags= dictionary;
    }

}

-(void)findNodes:(TBXMLElement *)xmlElement withWay:(OSMWay *)way
{
    
    //int64_t osmID = [[TBXML valueOfAttributeNamed:@"id" forElement:xmlElement] longLongValue];
    
    TBXMLElement* nd = [TBXML childElementNamed:@"nd" parentElement:xmlElement];
    
    while (nd) {
        int64_t nodeId = [[TBXML valueOfAttributeNamed:@"ref" forElement:nd] longLongValue];
        [way addNodeId:nodeId];
        nd = [TBXML nextSiblingNamed:@"nd" searchFromElement:nd];

    }
}
-(void)findMemebers:(TBXMLElement *)xmlElement withRelation:(OSMRelation *)relation
{
    TBXMLElement * memberXML = [TBXML childElementNamed:@"member" parentElement:xmlElement];
    
    while (memberXML) {
        NSString * typeString = [TBXML valueOfAttributeNamed:@"type" forElement:memberXML];
        int64_t elementOsmID = [[TBXML valueOfAttributeNamed:@"ref" forElement:memberXML] longLongValue];
        NSString * roleString = [TBXML valueOfAttributeNamed:@"role" forElement:memberXML];
        
        
		OSMMember* member = [[OSMMember alloc] init];
		member.type=typeString;
		member.ref=elementOsmID;
		member.role=roleString;
		[relation addMember:member];
        
        memberXML= [TBXML nextSiblingNamed:@"member" searchFromElement:memberXML];
    }
    
}
-(NSDictionary *)attributesWithTBXML:(TBXMLElement *)tbxmlElement
{
    TBXMLAttribute * attribute =tbxmlElement->firstAttribute;
    NSMutableDictionary * attributeDict = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%s" ,attribute->value] forKey:[NSString stringWithFormat:@"%s" ,attribute->name]];
    while (attribute->next) {
        attribute = attribute->next;
        
        [attributeDict setObject:[NSString stringWithFormat:@"%s" ,attribute->value] forKey:[NSString stringWithFormat:@"%s" ,attribute->name]];
    }
    return attributeDict;
}

@end

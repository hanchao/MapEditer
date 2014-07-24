//
//  Element.h
//  OSM POI Editor
//
//  Created by David on 4/16/13.
//
//

#import <Foundation/Foundation.h>

@interface OSMElement : NSObject


@property (nonatomic,strong) NSMutableDictionary * tags;
@property (nonatomic) int64_t elementID;
@property (nonatomic,strong) NSString * user;
@property (nonatomic) int64_t uid;
@property (nonatomic) int64_t version;
@property (nonatomic) int64_t changeset;
@property (nonatomic,strong) NSString * action;
@property (nonatomic,strong) NSDate * timeStamp;

-(id)initWithDictionary:(NSDictionary *)dictionary;
-(void)addMetaData:(NSDictionary *)dictionary;
-(NSString *)formattedDate;
-(void)addDateWithString:(NSString *)dateString;
//-(NSString *)idKeyPrefix;
-(NSString *)tableName;
-(NSString *)tagsTableName;

+ (NSDateFormatter *)defaultDateFormatter;

@end

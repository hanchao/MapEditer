//
//  Node.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMNode.h"


@implementation OSMNode

-(void)addMetaData:(NSDictionary *)dictionary
{
    [super addMetaData:dictionary];
    self.latitude = [dictionary[@"latitude"] doubleValue];
    self.longitude = [dictionary[@"longitude"] doubleValue];
}

-(NSString*) description {
	return [NSString stringWithFormat:@"Node(%lli)%f,%f", self.elementID, self.latitude, self.longitude];
}

-(CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

-(void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    self.latitude = coordinate.latitude;
    self.longitude = coordinate.longitude;
}

-(NSString *)tableName
{
    return @"nodes";
}
-(NSString *)tagsTableName
{
    return @"nodes_tags";
}

@end

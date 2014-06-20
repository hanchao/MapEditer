//
//  OSMStreamParser.h
//  OSM POI Editor
//
//  Created by David Chiles on 2/13/14.
//
//

#import "OSMParser.h"

@interface OSMStreamParser : OSMParser <NSXMLParserDelegate,NSStreamDelegate>

@property (nonatomic, strong) NSOutputStream *outputStream;

@end

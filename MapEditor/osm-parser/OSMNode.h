//
//  Node.h
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OSMElement.h"

/**
 This class describes a Node as defined in a .osm XML file.
 */
@interface OSMNode : OSMElement

/** This node latitude. (WGS 84 - SRID 4326) */
@property (nonatomic)double latitude;
/** This node longitude. (WGS 84 - SRID 4326) */
@property (nonatomic)double longitude;

@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

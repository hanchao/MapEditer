//
//  Note.h
//  OSM POI Editor
//
//  Created by David on 7/12/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OSMComment;

@interface OSMNote : NSObject

@property (nonatomic) int64_t id;
@property (nonatomic) BOOL isOpen;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic,strong) NSArray * commentsArray;
@property (nonatomic,strong) NSDate * dateCreated;
@property (nonatomic,strong) NSDate * dateClosed;

-(void)addComment:(OSMComment *)comment;


@end

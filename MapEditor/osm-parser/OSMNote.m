//
//  Note.m
//  OSM POI Editor
//
//  Created by David on 7/12/13.
//
//

#import "OSMNote.h"
#import "OSMComment.h"

@implementation OSMNote

-(id)init
{
    if (self = [super init]) {
        self.id = 0;
    }
    return self;
}


-(void)addComment:(OSMComment *)comment
{
    if ([self.commentsArray count]) {
        NSMutableArray * mutableComments = [self.commentsArray mutableCopy];
        [mutableComments addObject:comment];
        self.commentsArray = mutableComments;
    }
    else{
        self.commentsArray = @[comment];
    }
}
@end

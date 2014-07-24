//
//  Comment.m
//  OSM POI Editor
//
//  Created by David on 7/12/13.
//
//

#import "OSMComment.h"

@implementation OSMComment


-(NSString *)username
{
    if(!_username)
    {
        _username = @"Anonymous";
    }
    return _username;
}

@end

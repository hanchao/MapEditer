#import "OPEManagedOsmNode.h"
#import "OPEManagedOsmTag.h"


@interface OPEManagedOsmNode ()

// Private interface goes here.

@end


@implementation OPEManagedOsmNode

-(CLLocationCoordinate2D) center
{
    return CLLocationCoordinate2DMake([self.lattitude doubleValue], [self.longitude doubleValue]);
}

- (NSData *) createXMLforChangset: (int64_t) changesetNumber
{
    double lat = self.lattitudeValue;
    double lon = self.longitudeValue;
    NSLog(@"upload lat: %f",lat);
    NSLog(@"upload lon: %f",lon);
    NSLog(@"changeset number: %lld",changesetNumber);
    
    NSMutableString *nodeXML = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
    
    [nodeXML appendString: @"<osm version=\"0.6\" generator=\"OSMPOIEditor\">"];
    [nodeXML appendFormat:@"<node lat=\"%f\" lon=\"%f\" changeset=\"%lld\">",lat,lon, changesetNumber];
    
    [nodeXML appendString:[self tagsXML]];
    
    [nodeXML appendString:@"</node> </osm>"];
    
    return [nodeXML dataUsingEncoding:NSUTF8StringEncoding];
    
}
- (NSData *) updateXMLforChangset: (int64_t) changesetNumber
{
    NSMutableString * xml = [NSMutableString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
    [xml appendString:@"<osm version=\"0.6\" generator=\"OSMPOIEditor\">"];
    [xml appendFormat:@"<node id=\"%lld\" lat=\"%f\" lon=\"%f\" version=\"%lld\" changeset=\"%lld\">",self.osmIDValue,self.lattitudeValue,self.longitudeValue,self.versionValue, changesetNumber];
    
    [xml appendString:[self tagsXML]];
    
    [xml appendFormat: @"</node> @</osm>"];
    
    
    return [xml dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *) deleteXMLforChangset: (int64_t) changesetNumber
{
    double lat = self.lattitudeValue;
    double lon = self.longitudeValue;
    NSLog(@"upload lat: %f",lat);
    NSLog(@"upload lon: %f",lon);
    NSLog(@"changeset number: %lld",changesetNumber);
    
    NSMutableString *nodeXML = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
    
    [nodeXML appendString: @"<osm version=\"0.6\" generator=\"OSMPOIEditor\">"];
    [nodeXML appendFormat: @"<node id=\"%lld\" lat=\"%f\" lon=\"%f\" version=\"%lld\" changeset=\"%lld\"/>",self.osmIDValue,lat,lon,self.versionValue, changesetNumber];
    [nodeXML appendString: @"</osm>"];
    
    return [nodeXML dataUsingEncoding:NSUTF8StringEncoding];
    
}

+(OPEManagedOsmNode *)fetchOrCreateNodeWithOsmID:(int64_t)nodeId
{
    NSPredicate *osmNodeFilter = [NSPredicate predicateWithFormat:@"%K == %lld",OPEManagedOsmElementAttributes.osmID,nodeId];
    
    NSArray * results = [OPEManagedOsmNode MR_findAllWithPredicate:osmNodeFilter];
    
    if (nodeId == 2198739325) {
        NSLog(@"help");
    }
    
    OPEManagedOsmNode * osmNode = nil;
    
    if([results count])
    {
        osmNode = [results lastObject];
    }
    else{
        osmNode = [OPEManagedOsmNode MR_createEntity];
        osmNode.osmIDValue = nodeId;
    }
    
    return osmNode;
}

+(OPEManagedOsmNode *)newNode
{
    OPEManagedOsmNode * newNode = [OPEManagedOsmNode MR_createEntity];
    newNode.osmIDValue = [OPEManagedOsmElement minID]-1;
    
    return newNode;
}

@end
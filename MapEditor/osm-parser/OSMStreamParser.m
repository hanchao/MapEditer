//
//  OSMStreamParser.m
//  OSM POI Editor
//
//  Created by David Chiles on 2/13/14.
//
//

#import "OSMStreamParser.h"

@interface OSMStreamParser ()

@property (nonatomic, strong) NSInputStream *inputStream;

@end

@implementation OSMStreamParser

-(id)init
{
    if (self = [super init]) {
        NSOutputStream * outputStream;
        NSInputStream * inputStream;
        [OSMStreamParser createBoundInputStream:&inputStream outputStream:&outputStream bufferSize:4096];
        self.inputStream = inputStream;
        self.inputStream.delegate = self;
        self.outputStream = outputStream;
        self.outputStream.delegate =self;
        [self.inputStream open];
        
        
        NSXMLParser * parser = [[NSXMLParser alloc] initWithStream:self.inputStream];
        parser.delegate = self;
    }
    return self;
}


#pragma - mark NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"Stream: %@, %lu",aStream,eventCode);
}

#pragma - mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSLog(@"Start Element: %@",elementName);
}

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize
{
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    assert( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) );
    
    readStream = NULL;
    writeStream = NULL;
    
    CFStreamCreateBoundPair(NULL,
                            ((inputStreamPtr  != nil) ? &readStream : NULL),
                            ((outputStreamPtr != nil) ? &writeStream : NULL),
                            (CFIndex) bufferSize);
    
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = (__bridge NSInputStream *)(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = (__bridge NSOutputStream *)(writeStream);
    }
}

@end

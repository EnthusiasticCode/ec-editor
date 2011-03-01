//
//  ECCodeIndexingFile.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexingFile.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ECCodeIndexingFile
@synthesize URL = _URL;
@synthesize extension = _extension;
@synthesize language = _language;
@synthesize buffer = _buffer;
@synthesize dirty = _dirty;

- (void)dealloc
{
    self.URL = nil;
    self.language = nil;
    self.buffer = nil;
    [super dealloc];
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        self.URL = url;
        NSString *extension = [url pathExtension];
        CFStringRef extension = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
        self.extension = (NSString *)extension;
        CFRelease(extension);
    }
    return self;
}

+ (id)fileWithURL:(NSURL *)url
{
    id file = [self alloc];
    file = [file initWithURL:url];
    return [file autorelease];
}

@end

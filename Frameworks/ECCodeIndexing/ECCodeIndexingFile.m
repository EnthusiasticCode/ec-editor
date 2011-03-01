//
//  ECCodeIndexingFile.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexingFile.h"

@interface ECCodeIndexingFile ()
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) NSString *extension;
@end

@implementation ECCodeIndexingFile
@synthesize URL = _URL;
@synthesize extension = _extension;
@synthesize language = _language;
@synthesize buffer = _buffer;
@synthesize dirty = _dirty;

- (void)dealloc
{
    self.URL = nil;
    self.extension = nil;
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
        self.extension = [url pathExtension];
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

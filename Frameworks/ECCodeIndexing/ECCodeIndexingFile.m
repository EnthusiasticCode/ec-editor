//
//  ECCodeIndexingFile.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexingFile.h"


@implementation ECCodeIndexingFile
@synthesize URL = _URL;
@synthesize language = _language;
@synthesize buffer = _buffer;

- (void)dealloc
{
    self.URL = nil;
    self.language = nil;
    self.buffer = nil;
    [super dealloc];
}

- (id)initWithURL:(NSURL *)url language:(NSString *)language buffer:(NSString *)buffer
{
    self = [super init];
    if (self)
    {
        self.URL = url;
        self.language = language;
        self.buffer = buffer;
    }
    return self;
}

+ (id)fileWithURL:(NSURL *)url language:(NSString *)language buffer:(NSString *)buffer
{
    id file = [self alloc];
    file = [file initWithURL:url language:language buffer:buffer];
    return [file autorelease];
}

@end

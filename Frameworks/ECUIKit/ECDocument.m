//
//  ECDocument.m
//  edit
//
//  Created by Uri Baghin on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDocument.h"


@implementation ECDocument

@synthesize path = path_;
@synthesize documentEdited = documentEdited_;

- (NSString *)displayName
{
    return [self.path lastPathComponent];
}

- (void)dealloc
{
    self.path = nil;
    [super dealloc];
}

- (BOOL)readFromPath:(NSString *)path error:(NSError **)error
{
    [NSException raise:@"Invalid subclass" format:@"Subclass should override method"];
    return NO;
}

- (BOOL)writeToPath:(NSString *)path error:(NSError **)error
{
    [NSException raise:@"Invalid subclass" format:@"Subclass should override method"];
    return NO;
}

@end

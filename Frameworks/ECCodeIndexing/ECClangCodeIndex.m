//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <clang-c/Index.h>
#import "ECCodeIndexSubclass.h"
#import "ECClangCodeIndex.h"
#import "ECClangCodeUnit.h"

@implementation ECClangCodeIndex

@synthesize index = _index;

- (void)dealloc
{
    clang_disposeIndex(self.index);
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _index = clang_createIndex(0, 1);
    return self;
}

+ (void)load
{
    [ECCodeIndex registerExtension:self];
}

/* leave this out for now until we figure out how to best plug it in the textmate one
- (float)implementsProtocol:(Protocol *)protocol forFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    ECASSERT([fileURL isFileURL]);
    NSString *fileExtension = [fileURL pathExtension];
    NSArray *supportedFileExtensions = [NSArray arrayWithObjects:@"h", @"c", @"cc", @"m", @"mm", nil];
    for (NSString *supportedExtension in supportedFileExtensions)
        if ([fileExtension isEqualToString:supportedExtension])
            return 1.0;
    return 0.0;
}
 */

- (id)codeUnitImplementingProtocol:(Protocol *)protocol withFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    return [[ECClangCodeUnit alloc] initWithIndex:self fileURL:fileURL language:language];
}

@end

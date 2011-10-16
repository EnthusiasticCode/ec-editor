//
//  TMCodeIndex.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMCodeIndex.h"
#import "TMBundle.h"

@implementation TMCodeIndex

+ (void)setBundleDirectory:(NSURL *)bundleDirectory
{
    [TMBundle setBundleDirectory:bundleDirectory];
}

@end

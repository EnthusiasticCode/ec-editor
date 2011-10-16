//
//  TMTheme.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMTheme.h"

static NSURL *_themeDirectory;

@implementation TMTheme

+ (NSURL *)themeDirectory
{
    return _themeDirectory;
}

+ (void)setThemeDirectory:(NSURL *)themeDirectory
{
    _themeDirectory = themeDirectory;
}

@end

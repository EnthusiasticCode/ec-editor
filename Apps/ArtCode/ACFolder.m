//
//  ACFolder.m
//  ArtCode
//
//  Created by Uri Baghin on 9/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFolder.h"
#import "ACURL.h"

@implementation ACFolder

- (NSURL *)ACURL
{
    return [NSURL ACURLForFolderAtPath:self.relativePath];
}

@end

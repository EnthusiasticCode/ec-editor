//
//  ACGroup.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACGroup.h"

@implementation ACGroup

- (NSURL *)fileURL
{
    NSURL *fileURL = self.parent.fileURL;
    if (self.concrete)
        fileURL = [fileURL URLByAppendingPathComponent:self.name];
    return fileURL;
}

@end

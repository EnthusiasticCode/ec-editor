//
//  ECArchive.h
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECArchive : NSObject

+ (BOOL)extractArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL;
+ (BOOL)compressDirectoryAtURL:(NSURL *)directoryURL toArchive:(NSURL *)archiveURL;

@end

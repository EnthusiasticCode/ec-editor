//
//  Archive.h
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArchiveUtilities : NSObject

+ (BOOL)extractArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL;
+ (BOOL)compressDirectoryAtURL:(NSURL *)directoryURL toArchive:(NSURL *)archiveURL;

@end


@interface NSURL (ArchiveUtitlies)

/// Indicates if the URL can be extracted by the ArchiveUtility.
- (BOOL)isArchiveURL;

@end
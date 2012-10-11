//
//  Archive.h
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArchiveUtilities : NSObject

/// Extracts the given archive, and returns the url of a temporary directory with the archive's contents on success or nil on error
/// Caller is responsible for deleting the temporary directory
+ (void)extractArchiveAtURL:(NSURL *)archiveURL completionHandler:(void(^)(NSURL *temporaryDirectoryURL))completionHandler;

/// Compresses the given files, and returns the url of a temporary directory containing an archive named "Archive.zip" on success or nil on error
/// Caller is responsible for deleting the temporary directory
+ (void)compressFileAtURLs:(NSArray *)urls completionHandler:(void(^)(NSURL *temporaryDirectoryURL))completionHandler;

@end


@interface NSURL (ArchiveUtitlies)

/// Indicates if the URL can be extracted by the ArchiveUtility.
- (BOOL)isArchiveURL;

@end
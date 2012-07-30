//
//  Archive.h
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArchiveUtilities : NSObject

+ (void)coordinatedExtractionOfArchiveAtURL:(NSURL *)archiveURL toURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler;
+ (void)coordinatedCompressionOfFilesAtURLs:(NSArray *)urls toArchiveAtURL:(NSURL *)archiveURL renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void(^)(NSError *error, NSURL *newURL))completionHandler;

@end


@interface NSURL (ArchiveUtitlies)

/// Indicates if the URL can be extracted by the ArchiveUtility.
- (BOOL)isArchiveURL;

@end
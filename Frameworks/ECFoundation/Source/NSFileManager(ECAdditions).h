//
//  NSFileManager-ECExtensions.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (ECAdditions)
- (BOOL)fileExistsAndIsDirectoryAtPath:(NSString *)path;
- (BOOL)fileExistsAndIsNotDirectoryAtPath:(NSString *)path;
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withExtensions:(NSArray *)extensions options:(NSDirectoryEnumerationOptions)options skipFiles:(BOOL)skipFiles skipDirectories:(BOOL)skipDirectories error:(NSError **)error;
- (NSArray *)subpathsOfDirectoryAtPath:(NSString *)path withExtensions:(NSArray *)extensions options:(NSDirectoryEnumerationOptions)options skipFiles:(BOOL)skipFiles skipDirectories:(BOOL)skipDirectories error:(NSError **)error;
@end

//
//  ECCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


/*! Superclass of all code indexers. Implement language agnostic functionality here.
 *
 * Code indexers encapsulate interaction with parsing and indexing libraries to provide language related functionality such as syntax aware highlighting, hyperlinking and completions.
 */

@protocol ECCodeIndexer <NSObject>
@property (nonatomic, readonly, copy) NSSet *handledLanguages;
@property (nonatomic, readonly, copy) NSSet *handledUTIs;
@property (nonatomic, readonly, copy) NSSet *handledFiles;
- (void)addFilesObject:(NSURL *)fileURL;
- (void)removeFilesObject:(NSURL *)fileURL;
- (void)setLanguage:(NSString *)language forFile:(NSURL *)fileURL;
- (void)setBuffer:(NSString *)buffer forFile:(NSURL *)fileURL;
- (NSArray *)completionsForFile:(NSURL *)fileURL withSelection:(NSRange)selection;
- (NSArray *)diagnosticsForFile:(NSURL *)fileURL;
- (NSArray *)fixItsForFile:(NSURL *)fileURL;
- (NSArray *)tokensForFile:(NSURL *)fileURL inRange:(NSRange)range;
- (NSArray *)tokensForFile:(NSURL *)fileURL;
@end

@interface ECCodeIndexer : NSObject <ECCodeIndexer>
@end

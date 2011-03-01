//
//  ECCodeIndexerPlugin.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
@class ECCodeIndexingFile;

//! Protocol ECCodeIndexer plugins conform to.
//
// All methods are required.
@protocol ECCodeIndexerPlugin <ECCodeIndexer>
- (BOOL)loadFile:(ECCodeIndexingFile *)file;
- (BOOL)unloadFile:(ECCodeIndexingFile *)file;
// The following methods should be the same as the ones declared by the ECCodeIndexerPluginForwarding protocol
// The first argument will be changed from the file URL, to an ECCodeIndexingFile representing the file
- (NSArray *)completionsForFile:(ECCodeIndexingFile *)file withSelection:(NSRange)selection;
- (NSArray *)diagnosticsForFile:(ECCodeIndexingFile *)file;
- (NSArray *)fixItsForFile:(ECCodeIndexingFile *)file;
- (NSArray *)tokensForFile:(ECCodeIndexingFile *)file inRange:(NSRange)range;
- (NSArray *)tokensForFile:(ECCodeIndexingFile *)file;
@end

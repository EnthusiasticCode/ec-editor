//
//  ECCodeIndexerPlugin.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
@class ECCodeIndexingFile;

//! Protocol ECCodeIndexer plugins must conform to.
@protocol ECCodeIndexerPlugin <ECCodeIndexer, ECCodeIndexerPluginForwarding>
- (BOOL)loadFile:(ECCodeIndexingFile *)file;
- (BOOL)unloadFile:(ECCodeIndexingFile *)file;
@end

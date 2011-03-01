//
//  ECCodeIndexerPlugin.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"

//! Protocol ECCodeIndexer plugins conform to.
//
// Note about methods in ECCodeIndexerPluginForwarding:
// Plugins will be passed ECCodeIndexingFile instead of NSURL objects as file identifiers
@protocol ECCodeIndexerPlugin <ECCodeIndexer, ECCodeIndexerPluginForwarding>
- (BOOL)loadFile:(id)file;
- (BOOL)unloadFile:(id)file;
@end

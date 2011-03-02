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

//! Protocol declaring methods ECCodeIndexer and its plugins have in common.
//
// Plugins cannot override or call the ECCodeIndexer implementations.
@protocol ECCodeIndexer <NSObject>
@property (nonatomic, readonly, copy) NSDictionary *languageToExtensionMappingDictionary;
@property (nonatomic, readonly, copy) NSDictionary *extensionToLanguageMappingDictionary;
@property (nonatomic, readonly, copy) NSSet *loadedFiles;
@end

//! Protocol declaring methods ECCodeIndexer will forward to its plugins.
//
// While all methods are optional, they're safe to call, and will return nil values if not implemented.
// The first argument is always the NSURL for the file the method applies to.
@protocol ECCodeIndexerPluginForwarding
@optional
- (NSArray *)completionsForFile:(NSURL *)fileURL withSelection:(NSRange)selection;
- (NSArray *)diagnosticsForFile:(NSURL *)fileURL;
- (NSArray *)fixItsForFile:(NSURL *)fileURL;
- (NSArray *)tokensForFile:(NSURL *)fileURL inRange:(NSRange)range;
- (NSArray *)tokensForFile:(NSURL *)fileURL;
@end

@interface ECCodeIndexer : NSObject <ECCodeIndexer, ECCodeIndexerPluginForwarding>
- (BOOL)loadFile:(NSURL *)fileURL;
- (BOOL)unloadFile:(NSURL *)fileURL;
- (BOOL)setLanguage:(NSString *)language forFile:(NSURL *)fileURL;
- (BOOL)setBuffer:(NSString *)buffer forFile:(NSURL *)fileURL;
@end

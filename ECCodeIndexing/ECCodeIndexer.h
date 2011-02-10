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
@interface ECCodeIndexer : NSObject {

}
@property (nonatomic, readonly) NSString *language;
@property (nonatomic, readonly) NSString *source;
+ (void)loadLanguages;
+ (void)unloadLanguages;
+ (NSArray *)handledLanguages;
+ (NSArray *)handledExtensions;
- (id)initWithSource:(NSString *)source language:(NSString *)language;
- (id)initWithSource:(NSString *)source;
- (NSArray *)completionsForSelection:(NSRange)selection withUnsavedFileBuffers:(NSDictionary *)fileBuffers;
- (NSArray *)completionsForSelection:(NSRange)selection;
- (NSArray *)diagnostics;
- (NSArray *)tokensForRange:(NSRange)range withUnsavedFileBuffers:(NSDictionary *)fileBuffers;
- (NSArray *)tokensForRange:(NSRange)range;
- (NSArray *)tokensWithUnsavedFileBuffers:(NSDictionary *)fileBuffers;
- (NSArray *)tokens;

@end

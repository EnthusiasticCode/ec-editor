//
//  ECCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


//TODO: turn this into a class cluster: http://seanmurph.com/weblog/make-your-own-abstract-factory-class-cluster-in-objective-c/

/*! Superclass of all code indexers. Implement language agnostic functionality here.
 *
 * Code indexers encapsulate interaction with parsing and indexing libraries to provide language related functionality such as syntax aware highlighting, hyperlinking and completions.
 */
@interface ECCodeIndexer : NSObject {

}
/*! Returns possible completions considering the parameters.
 *
 *\param selection The range of the currently selected text.
 *\param string A string representing the whole scope containing the selection.
 */
- (NSArray *)completionsWithSelection:(NSRange)selection inString:(NSString *)string;
- (NSRange)completionRangeWithSelection:(NSRange)selection inString:(NSString *)string;
- (void)setActiveFile:(NSString *)file;
- (void)loadFile:(NSString *)file;
- (void)unloadFile:(NSString *)file;
- (NSArray *)files;
- (NSArray *)diagnostics;
- (NSArray *)tokensForRange:(NSRange)range inFile:(NSString *)string;
- (NSArray *)tokensForRange:(NSRange)range;

@end

//
//  ECCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


/*! Protocol that describes interaction with code indexers. */
@protocol ECCodeIndexer <NSObject>
/*! Returns possible completions considering the parameters.
 *
 *\param selection The range of the currently selected text.
 *\param string A string representing the whole scope containing the selection.
 */
- (NSArray *)completionsWithSelection:(NSRange)selection inString:(NSString *)string;

@end

/*! Superclass of all code indexers. Implement language agnostic functionality here.
 *
 * Code indexers encapsulate interaction with parsing and indexing libraries to provide language related functionality such as syntax aware highlighting, hyperlinking and completions.
 */
@interface ECCodeIndexer : NSObject {

}

@end

//
//  ECClangCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ECCodeIndexer.h"

typedef enum ECClangLanguage
{
    ECClangLanguage_ObjectiveC = 1
} ECClangLanguage;

/*! Clang code indexer. Provides completion and syntax checking through Clang. */
@interface ECClangCodeIndexer : ECCodeIndexer{

}

@end

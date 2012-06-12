//
//  CodeIndexing.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TMIndex.h"

@interface TMIndex (Internal)

/// Extension support
/// Register a class as an extension of CodeIndex.
+ (void)registerExtension:(Class)extensionClass forKey:(id)key;

- (id)extensionForKey:(id)key;

@end

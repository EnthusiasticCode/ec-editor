//
//  ECCodeIndexing+Internal.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMIndex.h"
@class ECFileBuffer;

@interface TMIndex (Internal)

/// Extension support
/// Register a class as an extension of ECCodeIndex.
+ (void)registerExtension:(Class)extensionClass forKey:(id)key;

- (id)extensionForKey:(id)key;

@end

@protocol TMIndexExtension <NSObject>


@end


//
//  ECCodeIndex+Internal.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
@class ECFileBuffer;

@interface ECCodeIndex (Internal)

/// Extension support
/// Register a class as an extension of ECCodeIndex.
+ (void)registerExtension:(Class)extensionClass forKey:(id)key;

- (id)extensionForKey:(id)key;

@end

@interface ECCodeUnit (Internal)

+ (void)registerExtension:(Class)extensionClass forScopeIdentifier:(NSString *)scopeIdentifier forKey:(id)key;

- (id)initWithIndex:(ECCodeIndex *)index fileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier;

- (id)extensionForKey:(id)key;

@end

@protocol ECCodeIndexExtension <NSObject>



@end

@protocol ECCodeUnitExtension <NSObject>

- (id)initWithCodeUnit:(ECCodeUnit *)codeUnit;

@end
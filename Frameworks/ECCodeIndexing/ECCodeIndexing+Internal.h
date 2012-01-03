//
//  ECCodeIndexing+Internal.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexing.h"
@class ECFileBuffer;

@interface TMIndex (Internal)

/// Extension support
/// Register a class as an extension of ECCodeIndex.
+ (void)registerExtension:(Class)extensionClass forKey:(id)key;

- (id)extensionForKey:(id)key;

@end

@interface TMUnit (Internal)

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key;

- (id)initWithIndex:(TMIndex *)index fileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier;

- (id)extensionForKey:(id)key;

@end

@protocol TMIndexExtension <NSObject>


@end

@protocol TMUnitExtension <NSObject>

- (id)initWithCodeUnit:(TMUnit *)codeUnit;

@end
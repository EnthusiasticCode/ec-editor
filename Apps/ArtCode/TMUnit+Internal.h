//
//  TMUnit+Internal.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMUnit.h"
@class TMIndex;

@interface TMUnit (Internal)

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key;

- (id)initWithIndex:(TMIndex *)index fileBuffer:(FileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier;

- (id)extensionForKey:(id)key;

@end

@protocol TMUnitExtension <NSObject>

- (id)initWithCodeUnit:(TMUnit *)codeUnit;

@end

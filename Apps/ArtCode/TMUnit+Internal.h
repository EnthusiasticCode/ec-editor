//
//  TMUnit+Internal.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMUnit.h"


@interface TMUnit (Internal)

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key;

- (id)extensionForKey:(id)key;

@end

@protocol TMUnitExtension <NSObject>

- (id)initWithCodeUnit:(TMUnit *)codeUnit;

@end

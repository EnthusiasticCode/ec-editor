//
//  TMUnit+Internal.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMUnit.h"
@class TMIndex, ACProjectFile;

@interface TMUnit (Internal)

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key;

- (id)initWithProjectFile:(ACProjectFile *)projectFile;

- (id)extensionForKey:(id)key;

@end

@protocol TMUnitExtension <NSObject>

- (id)initWithCodeUnit:(TMUnit *)codeUnit;

@end

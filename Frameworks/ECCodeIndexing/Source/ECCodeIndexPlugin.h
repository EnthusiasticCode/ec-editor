//
//  ECCodeIndexPlugin.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeUnitPlugin.h"

@protocol ECCodeIndexPlugin <NSObject>
/// Returns a dictionary with languages for keys, and their default associated file extension as values.
- (NSDictionary *)languageToExtensionMap;
/// Returns a dictionary with file extensions for keys, and the languages they are usually associated to.
- (NSDictionary *)extensionToLanguageMap;
/// Returns a code unit for the given URL, with the given language.
- (id<ECCodeUnitPlugin>)unitPluginForURL:(NSURL *)url withLanguage:(NSString *)language;
@end

//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeUnit;

//! Protocol objects passed as file to track must conform to.
@protocol ECCodeIndexingFileTracking <NSObject>
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) NSString *unsavedContent;
@end

// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring
@interface ECCodeIndex : NSObject
- (NSDictionary *)languageToExtensionMap;
- (NSDictionary *)extensionToLanguageMap;
- (NSString *)languageForExtension:(NSString *)extension;
- (NSString *)extensionForLanguage:(NSString *)language;
- (NSSet *)trackedFiles;
- (BOOL)trackFile:(id<ECCodeIndexingFileTracking>)file;
- (ECCodeUnit *)unitForURL:(NSURL *)url withLanguage:(NSString *)language;
- (ECCodeUnit *)unitForURL:(NSURL *)url;
@end

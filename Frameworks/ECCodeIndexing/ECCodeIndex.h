//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeUnit.h"

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring.
@interface ECCodeIndex : NSObject

/// The directory where language bundles are saved
+ (NSURL *)bundleDirectory;
+ (void)setBundleDirectory:(NSURL *)bundleDirectory;

/// Registers a subclass as an extension of the receiver
+ (void)registerExtension:(Class)extensionClass;

/// Returns an array of NSString identifying the languages an index can support
+ (NSArray *)supportedLanguages;

/// Returns from 0.0 to 1.0 how extensively an index supports the given file
+ (float)supportForFile:(NSURL *)fileURL;

/// Create code units for files.

/// Returns a code unit for the given file, with the given language.
- (id<ECCodeUnit>)unitWithFileURL:(NSURL *)fileURL withLanguage:(NSString *)language;
/// Returns a code unit for the given file, with the automatically detected language.
- (id<ECCodeUnit>)unitWithFileURL:(NSURL *)fileURL;

@end

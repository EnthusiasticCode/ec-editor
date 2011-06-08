//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeUnit;

/// Protocol objects passed as files to track must conform to.
@protocol ECCodeIndexingFileObserving
@property (nonatomic, retain) NSString *file;
@property (nonatomic, retain) NSString *unsavedContent;
@end

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring.
@interface ECCodeIndex : NSObject
/// Returns a dictionary with languages for keys, and their default associated file extension as values.
- (NSDictionary *)languageToExtensionMap;
/// Returns a dictionary with file extensions for keys, and the languages they are usually associated to.
- (NSDictionary *)extensionToLanguageMap;
/// Returns the language associated to the given file extension.
- (NSString *)languageForExtension:(NSString *)extension;
/// Returns the default file extension for a file of the given language.
- (NSString *)extensionForLanguage:(NSString *)language;
/// Returns a set containing all files currently being observed by the code index.
- (NSArray *)observedFiles;
/// Attempts to add KVO observers to the given file to track changes to it.
/// If a file with the same file is already being tracked, returns NO. No observers are added to the file in that case.
- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject;
/// Removes all previously added KVO observers from the given file.
- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject;
/// Returns a code unit for the given file, with the given language.
- (ECCodeUnit *)unitForFile:(NSString *)file withLanguage:(NSString *)language;
/// Returns a code unit for the given file, with the default language as detected from the file.
- (ECCodeUnit *)unitForFile:(NSString *)file;
@end

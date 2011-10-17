//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ECCodeDiagnoser, ECCodeCompleter, ECCodeParser;

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

- (id<ECCodeCompleter>)completerWithFileURL:(NSURL *)fileURL language:(NSString *)language;
- (id<ECCodeDiagnoser>)diagnoserWithFileURL:(NSURL *)fileURL language:(NSString *)language;
- (id<ECCodeParser>)parserWithFileURL:(NSURL *)fileURL language:(NSString *)language;

@end

/// An enum identifying how the scope stack changed in order to trigger the enumeration
/// ECCodeScopeEnumerationStackChangeBreak specifies the stack wasn't changed properly, perhaps because the file or enumeration range started or ended abruptly or because of syntax errors
/// ECCodeScopeEnumerationStackChangePush specifies the enumeration was caused by pushing a new scope on the stack
/// ECCodeScopeEnumerationStackChangePop specifies the enumeration was caused by popping a scope from the stack, note that in this case the enumerated scope was also enumerated when it was originally pushed on the stack
/// ECCodeScopeEnumerationStackChangeContinue specifies the enumeration was caused by enumerating a sibling scope
typedef enum
{
    ECCodeScopeEnumerationStackChangeBreak,
    ECCodeScopeEnumerationStackChangePush,
    ECCodeScopeEnumerationStackChangePop,
    ECCodeScopeEnumerationStackChangeContinue,
} ECCodeScopeEnumerationStackChange;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@protocol ECCodeUnit <NSObject, NSFilePresenter>

/// The code index that generated the code unit.
@property (nonatomic, readonly, strong) ECCodeIndex *index;

/// The main source file the unit is interpreting.
@property (atomic, readonly, strong) NSURL *fileURL;

/// The language the unit is using to interpret the main source file's contents.
@property (nonatomic, readonly, strong) NSString *language;

@end

@protocol ECCodeCompleter <ECCodeUnit>

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (NSArray *)completionsAtOffset:(NSUInteger)offset;

@end

@protocol ECCodeDiagnoser <ECCodeUnit>

/// Returns warnings and errors in the unit
- (NSArray *)diagnostics;

@end

@protocol ECCodeParser <ECCodeUnit>

/// Parse the code unit's main source file
- (void)enumerateScopesInRange:(NSRange)range usingBlock:(void(^)(NSArray *scopes, NSRange range, ECCodeScopeEnumerationStackChange change, BOOL *skipChildren, BOOL *stop))block;

@end

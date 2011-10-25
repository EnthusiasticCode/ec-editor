//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#warning TODO: the whole ECCodeIndexing architecture requires uniquing, especially the TMSyntaxes

@protocol ECCodeUnit;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring.
@interface ECCodeIndex : NSObject

/// The directory where language bundles are saved
+ (NSURL *)bundleDirectory;
+ (void)setBundleDirectory:(NSURL *)bundleDirectory;

/// Code unit creation
/// The file must exist, but it can be empty
/// If the language or scope are not specified, they will be autodetected
/// Scope takes precedence over language
- (id)codeUnitImplementingProtocol:(Protocol *)protocol withFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope;

@end

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
- (void)enumerateCompletionsAtOffset:(NSUInteger)offset usingBlock:(void(^)(NSString *typedText, NSString *completion))block;

@end

typedef enum
{
    ECCodeDiagnosticSeverityIgnored = 0,
    ECCodeDiagnosticSeverityNote = 1,
    ECCodeDiagnosticSeverityWarning = 2,
    ECCodeDiagnosticSeverityError = 3, 
    ECCodeDiagnosticSeverityFatal = 4 
} ECCodeDiagnosticSeverity;

@protocol ECCodeDiagnoser <ECCodeUnit>

/// Returns warnings and errors in the unit
- (void)enumerateDiagnosticsInRange:(NSRange)range usingBlock:(void(^)(ECCodeDiagnosticSeverity severity, NSString *message, NSString *category, BOOL *stop))block;

@end

typedef enum
{
    ECCodeVisitorResultBreak,
    ECCodeVisitorResultContinue,
    ECCodeVisitorResultRecurse,
} ECCodeVisitorResult;

typedef ECCodeVisitorResult(^ECCodeVisitor)(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack);

@protocol ECCodeParser <ECCodeUnit>

/// Visit the scopes in the code unit's main source file
- (void)visitScopesInRange:(NSRange)range usingVisitor:(ECCodeVisitor)visitorBlock;

@end

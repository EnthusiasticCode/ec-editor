//
//  ECCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECCodeIndex;

/// An enum identifying the type of action to perform after a scope enumeration
/// ECCodeChildEnumerationActionBreak specifies the enumeration should stop
/// ECCodeChildEnumerationActionContinue specifies the enumeration should continue to the next sibling scope
/// ECCodeChildEnumerationActionRecurse specifies the enumeration should try to enumerate the current's scope first child scope, or continue to the next sibling scope if the current scope does not have children
typedef enum
{
    ECCodeChildEnumerationActionBreak,
    ECCodeChildEnumerationActionContinue,
    ECCodeChildEnumerationActionRecurse,
} ECCodeScopeEnumerationAction;

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

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (NSArray *)completionsAtOffset:(NSUInteger)offset;

/// Returns warnings and errors in the unit
- (NSArray *)diagnostics;

/// Parse the code unit's main source file
- (void)enumerateScopesInMainFileWithContent:(NSString *)content inRange:(NSRange)range usingBlock:(void(^)(NSArray *scopes, NSRange range, ECCodeScopeEnumerationStackChange change, BOOL *skipChildren, BOOL *cancel))block;


@end

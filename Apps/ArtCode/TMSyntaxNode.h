//
//  TMSyntaxNode.h
//  CodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CodeFile, OnigRegexp;

@interface TMSyntaxNode : NSObject <NSCopying>

+ (void)preload;

+ (TMSyntaxNode *)syntaxWithScopeIdentifier:(NSString *)scopeIdentifier;
+ (TMSyntaxNode *)syntaxForCodeFile:(CodeFile *)codeFile;

@property (atomic, weak, readonly) TMSyntaxNode *rootSyntax;

@property (atomic, strong, readonly) NSString *scopeName;
@property (atomic, strong, readonly) NSArray *fileTypes;
@property (atomic, strong, readonly) OnigRegexp *firstLineMatch;
@property (atomic, strong, readonly) OnigRegexp *foldingStartMarker;
@property (atomic, strong, readonly) OnigRegexp *foldingStopMarker;
@property (atomic, strong, readonly) OnigRegexp *match;
@property (atomic, strong, readonly) OnigRegexp *begin;
@property (atomic, strong, readonly) NSString *end;
@property (atomic, strong, readonly) NSString *name;
@property (atomic, strong, readonly) NSString *contentName;
@property (atomic, strong, readonly) NSDictionary *captures;
@property (atomic, strong, readonly) NSDictionary *beginCaptures;
@property (atomic, strong, readonly) NSDictionary *endCaptures;
@property (atomic, strong, readonly) NSArray *patterns;
@property (atomic, strong, readonly) NSDictionary *repository;
@property (atomic, strong, readonly) NSString *include;

@end


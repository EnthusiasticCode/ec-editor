//
//  TMSyntaxNode.h
//  CodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OnigRegexp;

@interface TMSyntaxNode : NSObject <NSCopying>

+ (TMSyntaxNode *)syntaxWithScopeIdentifier:(NSString *)scopeIdentifier;

+ (TMSyntaxNode *)syntaxForFileName:(NSString *)fileName;

+ (TMSyntaxNode *)syntaxForFirstLine:(NSString *)firstLine;

+ (TMSyntaxNode *)defaultSyntax;

/// A dictionary containing all the loaded syntaxes as values for syntax identifier as key.
+ (NSDictionary *)allSyntaxes;

@property (nonatomic, weak, readonly) TMSyntaxNode *rootSyntax;

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *qualifiedIdentifier;
@property (nonatomic, strong, readonly) NSArray *fileTypes;
@property (nonatomic, strong, readonly) OnigRegexp *firstLineMatch;
@property (nonatomic, strong, readonly) OnigRegexp *foldingStartMarker;
@property (nonatomic, strong, readonly) OnigRegexp *foldingStopMarker;
@property (nonatomic, strong, readonly) OnigRegexp *match;
@property (nonatomic, strong, readonly) OnigRegexp *begin;
@property (nonatomic, strong, readonly) NSString *end;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *contentName;
@property (nonatomic, strong, readonly) NSDictionary *captures;
@property (nonatomic, strong, readonly) NSDictionary *beginCaptures;
@property (nonatomic, strong, readonly) NSDictionary *endCaptures;
@property (nonatomic, strong, readonly) NSArray *patterns;
@property (nonatomic, strong, readonly) NSDictionary *repository;
@property (nonatomic, strong, readonly) NSString *include;

- (NSArray *)includedNodesWithRootNode:(TMSyntaxNode *)rootNode;

@end

//
//  TMSyntax.h
//  CodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FileBuffer, OnigRegexp;

extern NSString * const TMSyntaxScopeIdentifierKey;
extern NSString * const TMSyntaxFileTypesKey;
extern NSString * const TMSyntaxFirstLineMatchKey;
extern NSString * const TMSyntaxFoldingStartMarker;
extern NSString * const TMSyntaxFoldingStopMarker;
extern NSString * const TMSyntaxMatchKey;
extern NSString * const TMSyntaxBeginKey;
extern NSString * const TMSyntaxEndKey;
extern NSString * const TMSyntaxNameKey;
extern NSString * const TMSyntaxContentNameKey;
extern NSString * const TMSyntaxCapturesKey;
extern NSString * const TMSyntaxBeginCapturesKey;
extern NSString * const TMSyntaxEndCapturesKey;
extern NSString * const TMSyntaxPatternsKey;
extern NSString * const TMSyntaxRepositoryKey;
extern NSString * const TMSyntaxIncludeKey;

@interface TMSyntax : NSObject

+ (TMSyntax *)syntaxWithScopeIdentifier:(NSString *)scopeIdentifier;
+ (TMSyntax *)syntaxForFileBuffer:(FileBuffer *)fileBuffer;

- (TMSyntax *)rootSyntax;
- (NSDictionary *)attributes;

@end


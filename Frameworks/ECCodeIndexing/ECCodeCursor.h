//
//  ECCodeCursor.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeUnit.h"

typedef enum
{
    ECCodeCursorDeclaration = 1,
    ECCodeCursorReference,
    ECCodeCursorExpression,
    ECCodeCursorStatement,
    ECCodeCursorInvalid,
    ECCodeCursorPreprocessing,
} ECCodeCursorKind;

@interface ECCodeCursor : NSObject
@property (nonatomic, readonly, retain) ECCodeUnit *codeUnit;
@property (nonatomic, readonly, copy) NSString *language;
@property (nonatomic, readonly) ECCodeCursorKind kind;
@property (nonatomic, readonly, copy) NSString *detailedKind;
@property (nonatomic, readonly, copy) NSString *spelling;
@property (nonatomic, readonly, copy) NSURL *fileURL;
@property (nonatomic, readonly) NSUInteger offset;
@property (nonatomic, readonly) NSRange extent;
@property (nonatomic, readonly, copy) NSString *unifiedSymbolResolution;
- (id)initWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution;
+ (id)cursorWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution;
@end

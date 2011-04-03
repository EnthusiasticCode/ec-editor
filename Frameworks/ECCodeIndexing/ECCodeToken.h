//
//  ECCodeToken.h
//  edit
//
//  Created by Uri Baghin on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeCursor;

typedef enum ECCodeTokenKind
{
    ECCodeTokenKindPunctuation = 1,
    ECCodeTokenKindKeyword = 2,
    ECCodeTokenKindIdentifier = 3,
    ECCodeTokenKindLiteral = 4,
    ECCodeTokenKindComment = 5
} ECCodeTokenKind;

@interface ECCodeToken : NSObject
{
    NSUInteger _hash;
}
@property (nonatomic, readonly) ECCodeTokenKind kind;
@property (nonatomic, readonly, copy) NSString *spelling;
@property (nonatomic, readonly, copy) NSString *file;
@property (nonatomic, readonly) NSUInteger offset;
@property (nonatomic, readonly) NSRange extent;
@property (nonatomic, readonly, retain) ECCodeCursor *cursor;

- (id)initWithKind:(ECCodeTokenKind)kind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger )offset extent:(NSRange)extent cursor:(ECCodeCursor *)cursor;
+ (id)tokenWithKind:(ECCodeTokenKind)kind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger )offset extent:(NSRange)extent cursor:(ECCodeCursor *)cursor;

@end

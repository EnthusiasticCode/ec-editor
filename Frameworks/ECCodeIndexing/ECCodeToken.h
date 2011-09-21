//
//  ECCodeToken.h
//  edit
//
//  Created by Uri Baghin on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeCursor;

typedef enum
{
    ECCodeTokenKindPunctuation,
    ECCodeTokenKindKeyword,
    ECCodeTokenKindIdentifier,
    ECCodeTokenKindLiteral,
    ECCodeTokenKindComment,
} ECCodeTokenKind;

@interface ECCodeToken : NSObject
@property (nonatomic, readonly) ECCodeTokenKind kind;
@property (nonatomic, readonly, copy) NSString *spelling;
@property (nonatomic, readonly, strong) NSURL *fileURL;
@property (nonatomic, readonly) NSUInteger offset;
@property (nonatomic, readonly) NSRange extent;
@property (nonatomic, readonly, strong) ECCodeCursor *cursor;

@end

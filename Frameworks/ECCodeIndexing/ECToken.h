//
//  ECToken.h
//  edit
//
//  Created by Uri Baghin on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECSourceLocation;
@class ECSourceRange;

typedef enum ECTokenKind
{
    ECTokenKindPunctuation = 1,
    ECTokenKindKeyword = 2,
    ECTokenKindIdentifier = 3,
    ECTokenKindLiteral = 4,
    ECtokenKindComment = 5
} ECTokenKind;

@interface ECToken : NSObject
@property (nonatomic, readonly) ECTokenKind kind;
@property (nonatomic, readonly) NSString *spelling;
@property (nonatomic, readonly) ECSourceLocation *location;
@property (nonatomic, readonly) ECSourceRange *extent;

- (id)initWithKind:(ECTokenKind)kind spelling:(NSString *)spelling location:(ECSourceLocation *)location extent:(ECSourceRange *)extent;
+ (id)tokenWithKind:(ECTokenKind)kind spelling:(NSString *)spelling location:(ECSourceLocation *)location extent:(ECSourceRange *)extent;

@end

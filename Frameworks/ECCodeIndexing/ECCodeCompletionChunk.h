//
//  ECCodeCompletionChunk.h
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum ECCodeCompletionChunkKind
{
    ECCodeCompletionChunkKindOptional = 1,
    ECCodeCompletionChunkKindTypedText = 2,
    ECCodeCompletionChunkKindText = 3,
    ECCodeCompletionChunkKindPlaceHolder = 4,
    ECCodeCompletionChunkKindInformative = 5,
    ECCodeCompletionChunkKindCurrentParameter = 6,
    ECCodeCompletionChunkKindLeftParenthesis = 7,
    ECCodeCompletionChunkKindRightParenthesis = 8,
    ECCodeCompletionChunkKindLeftBracket = 9,
    ECCodeCompletionChunkKindRightBracket = 10,
    ECCodeCompletionChunkKindLeftBrace = 11,
    ECCodeCompletionChunkKindRightBrace = 12,
    ECCodeCompletionChunkKindLeftAngleBracket = 13,
    ECCodeCompletionChunkKindRightAngleBracket = 14,
    ECCodeCompletionChunkKindComma = 15,
    ECCodeCompletionChunkKindResultType = 16,
    ECCodeCompletionChunkKindSemicolon = 17,
    ECCodeCompletionChunkKindColon = 18,
    ECCodeCompletionChunkKindHorizontalSpace = 19,
    ECCodeCompletionChunkKindVerticalSpace = 20,
} ECCodeCompletionChunkKind;

@interface ECCodeCompletionChunk : NSObject
{
    NSUInteger _hash;
}
@property (nonatomic, readonly) ECCodeCompletionChunkKind kind;
@property (nonatomic, readonly, copy) NSString *string;

- (id)initWithKind:(ECCodeCompletionChunkKind)kind string:(NSString *)string;
- (id)initWithString:(NSString *)string;

+ (id)chunkWithKind:(ECCodeCompletionChunkKind)kind string:(NSString *)string;
+ (id)chunkWithString:(NSString *)string;

@end

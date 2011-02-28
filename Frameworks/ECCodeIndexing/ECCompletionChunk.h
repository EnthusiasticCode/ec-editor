//
//  ECCompletionChunk.h
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum ECCompletionChunkKind
{
    ECCompletionChunkKindOptional = 1,
    ECCompletionChunkKindTypedText = 2,
    ECCompletionChunkKindText = 3,
    ECCompletionChunkKindPlaceHolder = 4,
    ECCompletionChunkKindInformative = 5,
    ECCompletionChunkKindCurrentParameter = 6,
    ECCompletionChunkKindLeftParenthesis = 7,
    ECCompletionChunkKindRightParenthesis = 8,
    ECCompletionChunkKindLeftBracket = 9,
    ECCompletionChunkKindRightBracket = 10,
    ECCompletionChunkKindLeftBrace = 11,
    ECCompletionChunkKindRightBrace = 12,
    ECCompletionChunkKindLeftAngleBracket = 13,
    ECCompletionChunkKindRightAngleBracket = 14,
    ECCompletionChunkKindComma = 15,
    ECCompletionChunkKindResultType = 16,
    ECCompletionChunkKindSemicolon = 17,
    ECCompletionChunkKindColon = 18,
    ECCompletionChunkKindHorizontalSpace = 19,
    ECCompletionChunkKindVerticalSpace = 20,
} ECCompletionChunkKind;

@interface ECCompletionChunk : NSObject
@property (nonatomic, readonly) ECCompletionChunkKind kind;
@property (nonatomic, readonly) NSString *string;

- (id)initWithKind:(ECCompletionChunkKind)kind string:(NSString *)string;
- (id)initWithString:(NSString *)string;

+ (id)chunkWithKind:(ECCompletionChunkKind)kind string:(NSString *)string;
+ (id)chunkWithString:(NSString *)string;

@end

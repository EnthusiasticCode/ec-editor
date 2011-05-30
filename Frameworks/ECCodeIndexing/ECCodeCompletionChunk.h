//
//  ECCodeCompletionChunk.h
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    ECCodeCompletionChunkKindOptional,
    ECCodeCompletionChunkKindTypedText,
    ECCodeCompletionChunkKindText,
    ECCodeCompletionChunkKindPlaceHolder,
    ECCodeCompletionChunkKindInformative,
    ECCodeCompletionChunkKindCurrentParameter,
    ECCodeCompletionChunkKindLeftParenthesis,
    ECCodeCompletionChunkKindRightParenthesis,
    ECCodeCompletionChunkKindLeftBracket,
    ECCodeCompletionChunkKindRightBracket,
    ECCodeCompletionChunkKindLeftBrace,
    ECCodeCompletionChunkKindRightBrace,
    ECCodeCompletionChunkKindLeftAngleBracket,
    ECCodeCompletionChunkKindRightAngleBracket,
    ECCodeCompletionChunkKindComma,
    ECCodeCompletionChunkKindResultType,
    ECCodeCompletionChunkKindColon,
    ECCodeCompletionChunkKindSemicolon,
    ECCodeCompletionChunkKindHorizontalSpace,
    ECCodeCompletionChunkKindVerticalSpace,
} ECCodeCompletionChunkKind;

@interface ECCodeCompletionChunk : NSObject
@property (nonatomic, readonly) ECCodeCompletionChunkKind kind;
@property (nonatomic, readonly, copy) NSString *string;

- (id)initWithKind:(ECCodeCompletionChunkKind)kind string:(NSString *)string;
+ (id)chunkWithKind:(ECCodeCompletionChunkKind)kind string:(NSString *)string;

@end

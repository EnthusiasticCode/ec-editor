//
//  ACCodeIndexerDataSource.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeIndexerDataSource.h"
#import "ECTextStyle.h"

#import "ECCodeUnit.h"
#import "ECCodeToken.h"
#import "ECCodeCursor.h"

#import "ACCompletionController.h"

@implementation ACCodeIndexerDataSource {
    ACCompletionController *completionController;
}

static NSRange intersectionOfRangeRelativeToRange(NSRange range, NSRange inRange)
{
    NSRange intersectionRange = NSIntersectionRange(range, inRange);
    intersectionRange.location -= inRange.location;
    return intersectionRange;
}

@synthesize codeUnit;
@synthesize keywordStyle, commentStyle, referenceStyle, literalStyle, declarationStyle, preprocessingStyle;

- (id)init
{
    if ((self = [super init]))
    {
        keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" font:nil color:[UIColor blueColor]];
        commentStyle = [ECTextStyle textStyleWithName:@"Comment" font:nil color:[UIColor greenColor]];
        referenceStyle = [ECTextStyle textStyleWithName:@"Reference" font:nil color:[UIColor purpleColor]];
        literalStyle = [ECTextStyle textStyleWithName:@"Literal" font:nil color:[UIColor redColor]];
        declarationStyle = [ECTextStyle textStyleWithName:@"Declaration" font:nil color:[UIColor brownColor]];
        preprocessingStyle = [ECTextStyle textStyleWithName:@"Preprocessing" font:nil color:[UIColor orangeColor]];
        
        __weak ACCodeIndexerDataSource *this = self;
        [self addStylingBlock:^(NSMutableAttributedString *string, NSRange stringRange)
        {
            for (ECCodeToken *token in [this->codeUnit tokensInRange:stringRange withCursors:YES])
            {
                switch (token.kind)
                {
                    case ECCodeTokenKindKeyword:
                        [string addAttributes:this->keywordStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                        
                    case ECCodeTokenKindComment:
                        [string addAttributes:this->commentStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                        
                    case ECCodeTokenKindLiteral:
                        [string addAttributes:this->literalStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                        
                    default:
                    {
                        if (token.cursor.kind >= ECCodeCursorKindFirstDecl && token.cursor.kind <= ECCodeCursorKindLastDecl)
                            [string addAttributes:this->declarationStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        else if (token.cursor.kind >= ECCodeCursorKindFirstRef && token.cursor.kind <= ECCodeCursorKindLastRef)
                            [string addAttributes:this->referenceStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        else if (token.cursor.kind >= ECCodeCursorKindFirstPreprocessing && token.cursor.kind <= ECCodeCursorKindLastPreprocessing)
                            [string addAttributes:this->preprocessingStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                    }
                }
            }
        } forKey:@"IndexerStylingBlock"];
    }
    return self;
}

//- (UIViewController *)codeView:(ECCodeView *)codeView viewControllerForCompletionAtTextInRange:(NSRange)range
//{
//    if (!completionController)
//    {
//        completionController = [ACCompletionController new];
//    }
//    
//    
//}

@end

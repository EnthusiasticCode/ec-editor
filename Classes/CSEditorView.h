//
//  CSEditorView.h
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#import "IndexedPosition.h"
#import "IndexedRange.h"


@interface CSEditorView : UIView <UITextInput> {
    NSMutableAttributedString *_text;
    BOOL _editing;
    NSRange _markedNSRange;
    NSRange _selectedNSRange;
    CTFrameRef _frame;
    CGAffineTransform _coreTextTransformationMatrix;
    UITextInputStringTokenizer *_tokenizer;
    id<UITextInputDelegate> _inputDelegate;
}

@property(retain) NSMutableAttributedString *text;
@property BOOL editing;

- (void)setupCoreTextTransformationMatrix;
- (CGPoint)applyCoreTextTransformationMatrixToPoint:(CGPoint)point;
- (void)applyCoreTextTransformationMatrixInPlaceToPoints:(CGPoint *)points withCount:(int)count;
- (NSInteger)closestIndexToPoint:(CGPoint)point;

@end

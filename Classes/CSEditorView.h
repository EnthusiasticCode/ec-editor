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
    NSRange _markedNSRange;
    NSRange _selectedNSRange;
    CTFrameRef _frame;
    UITextInputStringTokenizer *_tokenizer;
    id<UITextInputDelegate> _inputDelegate;
}

@property(retain) NSMutableAttributedString *text;

@end

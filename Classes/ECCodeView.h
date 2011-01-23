//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OUIEditableFrame.h"

// TODO
// 1. Draw plain text
// 2. Text selection
// 3. Conform to text input/text editing
// 4. Add coloring function
//
// References
// search for "drawing managing text" in documentation.

@interface ECCodeView : UIView {
    // Content
    NSMutableAttributedString *content;
    
    // Core text objects and support
    CTFramesetterRef frameSetter;
    CTFrameRef contentFrame;
    CGPoint contentFrameOrigin;
    
    // Flags
    // TODO create smaller struct?
    BOOL contentFrameInvalid;
}

// Inset of the text in the rendering frame specified in text space.
@property (nonatomic, assign) UIEdgeInsets textInset;

@end

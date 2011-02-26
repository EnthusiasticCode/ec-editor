//
//  ECCaretView.h
//  edit
//
//  Created by Nicola Peduzzi on 26/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECCaretView : UIView {
@private
    
}

@property (nonatomic, getter = isBlinking) BOOL blink;
@property (nonatomic) CGPathRef caretShape;

// Draw the solid caret in the specified context
- (void)drawInContext:(CGContextRef)context;
@end

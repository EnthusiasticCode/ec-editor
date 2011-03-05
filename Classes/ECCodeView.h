//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextStyle.h"
#import "ECTextRange.h"
#import "ECTextPosition.h"

@interface ECCodeView : UIView {
@private

}

/// The text displayed by the code view.
@property (nonatomic, copy) NSString *text;

#pragma mark Text style API

/// The text style used for newly added text.
@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

/// Set the given style to the text range.
- (void)setTextStyle:(ECTextStyle *)style toTextRange:(ECTextRange *)range;

/// For every range in the ranges array, the corresponding style will be applied.
- (void)setTextStyles:(NSArray *)styles toTextRanges:(NSArray *)ranges;

@end

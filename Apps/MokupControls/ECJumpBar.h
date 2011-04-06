//
//  ECJumpBarView.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECJumpBar;

@protocol ECJumpBarDelegate <NSObject>

// TODO may need 'will' to actually be able to retrieve the button
/// Called when a button in the stack is popped. This method is called multiple time if more than one button are popped at once.
- (void)jumpBar:(ECJumpBar *)jumpBar didPopButtonAtStackIndex:(NSUInteger)index;

/// Called when there are too many buttons in the jump bar and they collapse.
- (void)jumpBar:(ECJumpBar *)jumpBar didCollapseFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

/// Called when the editable search string is changed.
- (void)jumpBar:(ECJumpBar *)jumpBar changedSearchStringTo:(NSString *)searchString;

@end

@interface ECJumpBar : UIView

@property (nonatomic, assign) id<ECJumpBarDelegate> delegate;

#pragma mark Visual Styles

/// The corner radius 
@property (nonatomic) CGFloat cornerRadius;

/// The font used for button's titles and search text.
@property (nonatomic, retain) UIFont *font;

/// The color of the text.
@property (nonatomic, retain) UIColor *textColor;

/// The color applied to the text in buttons and search text.
@property (nonatomic, retain) UIColor *textShadowColor;

/// The offset to be applied for button and search text shadow.
@property (nonatomic) CGSize textShadowOffset;

/// The color of buttons in normal state.
@property (nonatomic, retain) UIColor *buttonColor;

/// The color of buttons in highlight state.
@property (nonatomic, retain) UIColor *buttonHighlightColor;

/// The color of borders.
@property (nonatomic, retain) UIColor *borderColor;

/// Width of borders.
@property (nonatomic) CGFloat borderWidth;

#pragma mark Visual Constraints

/// The minimum with of the search field. If this number is lower than 1 it will be interpreted as a percentage of the receiver's width.
@property (nonatomic) CGFloat minimumSearchFieldWidth;

/// The minimum with of a button in the bar.
@property (nonatomic) CGFloat minimumStackButtonWidth;

/// The maximum width of a button in the bar.
@property (nonatomic) CGFloat maximumStackButtonWidth;

// The maximum allowed number of buttons in the bar.
@property (nonatomic) NSUInteger maximumButtonStackSize;

#pragma mark Hanling Button Stack

/// The current stack size. This property is read only.
@property (nonatomic, readonly) NSUInteger stackSize;

/// Get the button at the specified stack index.
- (UIButton *)buttonAtStackIndex:(NSUInteger)index;

// TODO add image to be used always or when the button is under a certian dimension.
/// Push a button into the stack adding it to the bar.
- (UIButton *)pushButtonWithTitle:(NSString *)title;

/// Pop the last inserted button from the stack, removing it from the bar.
- (void)popButton;

/// Pop a number of buttons to leave the stack with all buttons with index lower than the one specified.
- (void)popButtonsDownThruIndex:(NSUInteger)index;

#pragma mark Handling Search String

/// The search string.
@property (nonatomic, retain) NSString *searchString;

@end

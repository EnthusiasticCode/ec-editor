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
@optional

/// Called when a control is pushed to the stack.
- (void)jumpBar:(ECJumpBar *)jumpBar didPushControl:(UIControl *)control atStackIndex:(NSUInteger)index;

// TODO may need 'will' to actually be able to retrieve the button
/// Called when a control in the stack is popped. This method is called multiple time if more than one control are popped at once.
- (void)jumpBar:(ECJumpBar *)jumpBar didPopControl:(UIControl *)control atStackIndex:(NSUInteger)index;

/// Called when there are too many controls in the jump bar and they collapse.
- (void)jumpBar:(ECJumpBar *)jumpBar didCollapseToControl:(UIControl *)control collapsedRange:(NSRange)collapsedRange;

/// Called when the editable search string is changed.
- (void)jumpBar:(ECJumpBar *)jumpBar changedSearchStringTo:(NSString *)searchString;

@end

@interface ECJumpBar : UIView {
@protected
    /// Array used to store controls pushed to the receiver.
    NSMutableArray *controlsStack;
}

@property (nonatomic, weak) id<ECJumpBarDelegate> delegate;

#pragma mark Visual Styles

/// The corner radius 
@property (nonatomic) CGFloat cornerRadius;

/// The font used for button's titles and search text.
@property (nonatomic, strong) UIFont *font;

/// The color of the text.
@property (nonatomic, strong) UIColor *textColor;

/// The color applied to the text in buttons and search text.
@property (nonatomic, strong) UIColor *textShadowColor;

/// The offset to be applied for button and search text shadow.
@property (nonatomic) CGSize textShadowOffset;

/// The color of buttons in normal state.
@property (nonatomic, strong) UIColor *buttonColor;

/// The color of buttons in highlight state.
@property (nonatomic, strong) UIColor *buttonHighlightColor;

/// The color of borders.
@property (nonatomic, strong) UIColor *borderColor;

/// Width of borders.
@property (nonatomic) CGFloat borderWidth;

/// Insets of texts in the receiver.
@property (nonatomic) UIEdgeInsets textInsets;

// TODO activate this
/// Margin of stack controls in the receiver.
//@property (nonatomic) UIEdgeInsets controlMargin;

#pragma mark Visual Constraints

/// The minimum with of the search field. If this number is lower than 1 it will be interpreted as a percentage of the receiver's width.
@property (nonatomic) CGFloat minimumSearchFieldWidth;

/// The minimum with of a button in the bar.
@property (nonatomic) CGFloat minimumStackButtonWidth;

/// The maximum width of a button in the bar.
@property (nonatomic) CGFloat maximumStackButtonWidth;

#pragma mark Handling Controls Stack

/// The current stack size. This property is read only.
@property (nonatomic, readonly) NSUInteger stackSize;

/// Gets the control at the specified stack index.
- (UIControl *)controlAtStackIndex:(NSUInteger)index;

/// Gets the title of the control at the given stack index.
- (NSString *)titleOfControlAtStackIndex:(NSUInteger)index;

// TODO add image to be used always or when the button is under a certian dimension.
/// Push a button into the stack adding it to the bar.
- (void)pushControlWithTitle:(NSString *)title animated:(BOOL)animated;

/// Pop the last inserted button from the stack, removing it from the bar.
- (void)popControlAnimated:(BOOL)animated;

/// Pop a number of buttons to leave the stack with all buttons with index lower than the one specified.
- (void)popControlsDownThruIndex:(NSUInteger)index animated:(BOOL)animated;

#pragma mark Handling Search String

/// The search string.
@property (nonatomic, strong) NSString *searchString;

#pragma mark Generating Stack Controls

/// Override this method to make the jump bar use a custom \c UIControl as items in the stack.
- (UIControl *)createStackControlWithTitle:(NSString *)title;

@end

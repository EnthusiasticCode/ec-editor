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

/// This method is called when a jump element is selected by the user with a tap. If index is NSNotFound, the element represent the collapse element.
- (void)jumpBar:(ECJumpBar *)jumpBar didSelectJumpElement:(UIView *)jumpElement atIndex:(NSUInteger)index;

/// Inform the delegate of the newly created jump element. To be used for further customizations of the element.
- (void)jumpBar:(ECJumpBar *)jumpBar didPushJumpElement:(UIView *)jumpElement atIndex:(NSUInteger)index;

/// Return a value indicating if the given element can be collapsed.
- (BOOL)jumpBar:(ECJumpBar *)jumpBar canCollapseJumpElementAtIndex:(NSUInteger)index;

@end

@interface ECJumpBar : UIView <UIAppearanceContainer>

@property (nonatomic, weak) IBOutlet id<ECJumpBarDelegate> delegate;

#pragma mark Visual Styles

/// A view used as the background.
@property (nonatomic, strong) UIView *backgroundView;

/// The minimum with of the search field. 
/// If this number is lower than 1 it will be interpreted as a percentage of the receiver's width.
@property (nonatomic) CGFloat minimumTextElementWidth UI_APPEARANCE_SELECTOR;

/// Insets to apply to text element's frame.
@property (nonatomic) UIEdgeInsets textElementInsets UI_APPEARANCE_SELECTOR;

/// A margin to apply to jump elements and collapse element.
@property (nonatomic) UIEdgeInsets jumpElementMargins UI_APPEARANCE_SELECTOR;

/// The minimum with of a button in the bar.
@property (nonatomic) CGFloat minimumJumpElementWidth UI_APPEARANCE_SELECTOR;

/// The maximum width of a button in the bar.
@property (nonatomic) CGFloat maximumJumpElementWidth UI_APPEARANCE_SELECTOR;

#pragma mark Fixed Elements

/// A view positioned at the left side of the bar, before any other element.
/// Default to nil.
@property (nonatomic, strong) UIView *backElement;

/// A \c UITextView used as text positioned in the remaining right space.
@property (nonatomic, strong) UITextField *textElement;

#pragma mark Managing Jump Elements

/// The jump elements array.
@property (nonatomic, readonly, strong) NSArray *jumpElements;

/// Add an element to the end of the jump bar stack.
- (void)pushJumpElementWithPathComponent:(NSString *)pathComponent animated:(BOOL)animated;

/// Remove the last jump element.
- (void)popJumpElementAnimated:(BOOL)animated;

/// Remove an element and all it's descending elements.
- (void)popThroughJumpElementAtIndex:(NSUInteger)elementIndex animated:(BOOL)animated;

#pragma mark Managing Elements via Jump Path

/// Gets or set the jump elements in form of path. The path has to be in the format:
/// /element1/element2/...
@property (nonatomic, copy) NSString *jumpPath;
- (void)setJumpPath:(NSString *)jumpPath animated:(BOOL)animated;

/// Returns a jump path constructed from the first element up to the given element included.
- (NSString *)jumpPathUpThroughElementAtIndex:(NSUInteger)elementIndex;

@end


/// A button used for the dynamic part of the jump bar. This class is intended to be used as an appearance selector.
@interface ECJumpBarElementButton : UIButton
@end

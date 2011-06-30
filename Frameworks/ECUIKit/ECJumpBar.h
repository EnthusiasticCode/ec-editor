//
//  ECJumpBarView.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+ReuseIdentifier.h"

@class ECJumpBar;

@protocol ECJumpBarDelegate <NSObject>
@required

/// Ask the delegate for an element with the given path component that will be displayed in
/// the provided index. The delegate sould use dequeueReusableJumpElementWithIdentifier: to
/// see if an element is already created like in UITableView.
/// Use UIView's reuseIdentifier addition property to set the reuse identifier of a newly
/// created element.
/// If index is NSNotFound, the collapse element should be returned.
- (UIView *)jumpBar:(ECJumpBar *)jumpBar elementForJumpPathComponent:(NSString *)pathComponent index:(NSUInteger)componentIndex;

/// Return the path component for the given element.
/// If this methods return nil, the title or text property of the element will be used.
- (NSString *)jumpBar:(ECJumpBar *)jumpBar pathComponentForJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex;

@optional

// TODO see if use this method, it will introduce quite a lot of work
//- (BOOL)jumpBar:(ECJumpBar *)jumpBar shouldResizeJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex;

/// Return a value indicating if the given element can be collapsed.
- (BOOL)jumpBar:(ECJumpBar *)jumpBar canCollapseJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex;

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

/// The element to use as a placeholder representing all collapsed elements.
/// Default to an UIButton with "..." as title.
@property (nonatomic, strong) UIView *collapseElement;

#pragma mark Managing Jump Elements

/// The jump elements array.
@property (nonatomic, readonly, strong) NSArray *jumpElements;

/// Add an element to the end of the jump bar stack.
- (void)pushJumpElementWithPathComponent:(NSString *)pathComponent animated:(BOOL)animated;

/// Remove the last jump element.
- (void)popJumpElementAnimated:(BOOL)animated;

/// Remove an element and all it's descending elements.
- (void)popThroughJumpElement:(UIView *)element animated:(BOOL)animated;

#pragma mark Jump Elements Reuse

/// Try to dequeue a previously used and popped element. This method may return nil.
- (UIView *)dequeueReusableJumpElementWithIdentifier:(NSString *)identifier;

#pragma mark Managing Elements via Jump Path

@property (nonatomic, copy) NSString *jumpPath;
- (void)setJumpPath:(NSString *)jumpPath animated:(BOOL)animated;

- (void)pushJumpElementsForPath:(NSString* )path animated:(BOOL)animated;

@end

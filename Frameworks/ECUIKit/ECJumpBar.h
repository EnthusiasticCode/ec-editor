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

/// Create and return a view for the path component at the given index. 
/// If this methods return nil, a UIButton will be used instead.
- (UIView *)jumpBar:(ECJumpBar *)jumpBar createElementForJumpPathComponent:(NSString *)pathComponent index:(NSUInteger)componentIndex;

/// Return the path component for the given element.
/// If this methods return nil, the title or text property of the element will be used.
- (NSString *)jumpBar:(ECJumpBar *)jumpBar pathComponentForJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex;

// TODO see if use this method, it will introduce quite a lot of work
//- (BOOL)jumpBar:(ECJumpBar *)jumpBar shouldResizeJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex;

/// Return a value indicating if the given element can be collapsed.
- (BOOL)jumpBar:(ECJumpBar *)jumpBar canCollapseJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex;

@end

@interface ECJumpBar : UIView <UIAppearanceContainer>

@property (nonatomic, weak) id<ECJumpBarDelegate> delegate;

#pragma mark Visual Styles

/// A view used as the background.
@property (nonatomic, strong) UIView *backgroundView;

/// The minimum with of the search field. 
/// If this number is lower than 1 it will be interpreted as a percentage of the receiver's width.
@property (nonatomic) CGFloat minimumTextElementWidth UI_APPEARANCE_SELECTOR;

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
@property (nonatomic, strong) UITextView *textElement;

/// The element to use as a placeholder representing all collapsed elements.
/// Default to an UIButton with "..." as title.
@property (nonatomic, strong) UIView *collapseElement;

#pragma mark Managing Jump Elements

/// Creates a default element for the given component in case the delegate
/// method is not implemented.
- (UIView *)createDefaultElementForJumpPathComponent:(NSString *)pathComponent;

/// The jump elements array.
@property (nonatomic, readonly, strong) NSArray *jumpElements;

/// Add an element to the end of the jump bar stack.
- (void)pushJumpElementWithPathComponent:(NSString *)pathComponent animated:(BOOL)animated;

#pragma mark Managing Elements via Jump Path

@property (nonatomic, copy) NSString *jumpPath;
- (void)setJumpPath:(NSString *)jumpPath animated:(BOOL)animated;

- (void)pushJumpElementsForPath:(NSString* )path animated:(BOOL)animated;

@end

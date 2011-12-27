//
//  ACTopBarTitleControl.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    ACControlStateLoading = 1 << 4
};

@interface ACTopBarTitleControl : UIView

/// The button used as clickable background.
@property (nonatomic, strong, readonly) UIButton *backgroundButton;

#pragma mark Managin Title Fragments

/// Provides title fragments to display. A fragment can be either a NSString or a UIImage.
@property (nonatomic, strong) NSArray *titleFragments;

/// Indicates which title fragments are active. If nil, the last title fragment will be set active by default.
@property (nonatomic, strong) NSIndexSet *selectedTitleFragments;

/// Set the tint to apply to selected title fragments
@property (nonatomic, strong) UIColor *selectedTitleFragmentsTint UI_APPEARANCE_SELECTOR;

/// Set the tint to apply to unselected title fragments
@property (nonatomic, strong) UIColor *secondaryTitleFragmentsTint UI_APPEARANCE_SELECTOR;

/// Defines the gap between fragments on the same line.
@property (nonatomic) CGFloat gapBetweenFragments UI_APPEARANCE_SELECTOR;

/// Insets to apply to the content.
@property (nonatomic) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIFont *selectedFragmentFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *secondaryFragmentFont UI_APPEARANCE_SELECTOR;

#pragma mark Additional Modes

/// Indicates if the title control should show a loading animated background.
@property (nonatomic, getter = isLoadingMode) BOOL loadingMode;

@end


/// Forwards some UIButton methods to the backgroundButton
@interface ACTopBarTitleControl (UIBUttonForwarding)

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (UIImage *)backgroundImageForState:(UIControlState)state UI_APPEARANCE_SELECTOR;

@end


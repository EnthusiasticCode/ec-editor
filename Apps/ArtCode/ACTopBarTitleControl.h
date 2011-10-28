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

@interface ACTopBarTitleControl : UIButton

#pragma mark Managin Title Fragments

/// Provides title fragments to display. A fragment can be either a NSString or a UIImage.
@property (nonatomic, strong) NSArray *titleFragments;

/// Indicates which title fragments are active. If nil, the last title fragment will be set active by default.
@property (nonatomic, strong) NSIndexSet *selectedTitleFragments;

/// Set the tint to apply to unselected title fragments
@property (nonatomic, strong) UIColor *secondaryTitleFragmentsTint UI_APPEARANCE_SELECTOR;

/// Defines the gap between fragments on the same line.
@property (nonatomic) CGFloat gapBetweenFragments UI_APPEARANCE_SELECTOR;

#pragma mark Additional Modes

/// Indicates if the title control should show a loading animated background.
@property (nonatomic, getter = isLoadingMode) BOOL loadingMode;

@end

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

/// Provides title fragments to display. A fragment can be either a NSString or a UIImage.
@property (nonatomic, strong) NSArray *titleFragments;

/// Indicates which title fragments are active. If nil, the last title fragment will be set active by default.
@property (nonatomic, strong) NSIndexSet *selectedTitleFragments;

/// Indicates if the title control should show a loading animated background.
@property (nonatomic, getter = isLoadingMode) BOOL loadingMode;

@end

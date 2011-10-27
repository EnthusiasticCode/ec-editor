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

/// Indicates if the title control should show a loading animated background.
@property (nonatomic, getter = isLoadingMode) BOOL loadingMode;

@end

//
//  ECCustomizableScrollView.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 02/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// A scroll view that can perform custom code blocks on common overloaded operarions.
@interface ECCustomizableScrollView : UIScrollView

@property (nonatomic, copy) void (^layoutSubviewsBlock)(UIScrollView *view);

@end

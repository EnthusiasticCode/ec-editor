//
//  ECBlockView.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 21/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// A view taht is customizable via blocks
@interface ECBlockView : UIView

@property (nonatomic, copy) void (^layoutSubviewsBlock)(UIView *view);

@end

//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextStyle.h"

@interface ECCodeView : UIView {
@private

}

/// The text displayed by the code view.
@property (nonatomic, copy) NSString *text;

/// The text style used for newly added text.
@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

@end

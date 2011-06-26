//
//  ECSwipeGestureRecognizer.h
//  ACUI
//
//  Created by Nicola Peduzzi on 25/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface ECSwipeGestureRecognizer : UISwipeGestureRecognizer {
@private
    NSTimeInterval beginTimestamp;
}

@property (nonatomic) NSTimeInterval numberOfTouchesRequiredImmediatlyOrFailAfterInterval;

@end

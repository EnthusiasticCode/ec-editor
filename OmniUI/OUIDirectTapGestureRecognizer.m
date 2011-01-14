// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUIDirectTapGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView.h>



static BOOL _failOnIndirectTouch(UIGestureRecognizer *self, NSSet *touches, UIEvent *event)
{
    UIView *directView = self.view;
    UIWindow *directWindow = directView.window;
    
    for (UITouch *touch in touches) {
        CGPoint windowPoint = [touch locationInView:directWindow];
        UIView *hitView = [directWindow hitTest:windowPoint withEvent:event];
        if (hitView != directView) {
            self.state = UIGestureRecognizerStateFailed;
            return YES;
        }
    }
    
    return NO;
}

@implementation OUIDirectTapGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
    if (_failOnIndirectTouch(self, touches, event))
        return;
    [super touchesBegan:touches withEvent:event];
}

@end

@implementation OUIDirectLongPressGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
    if (_failOnIndirectTouch(self, touches, event))
        return;
    [super touchesBegan:touches withEvent:event];
}

@end

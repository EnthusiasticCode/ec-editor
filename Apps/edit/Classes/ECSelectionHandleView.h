//
//  ECSelectionHandleView.h
//  edit
//
//  Created by Nicola Peduzzi on 04/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECSelectionHandleView;

@protocol ECSelectionHandleViewDelegate <NSObject>

- (void)selectionHandle:(ECSelectionHandleView *)handle draggedTo:(CGPoint)point andStop:(BOOL)stopped;

@end

enum
{
    ECSelectionHandleSideNone   = 0,
    ECSelectionHandleSideRight  = 1 << 0,
    ECSelectionHandleSideTop    = 1 << 1,
    ECSelectionHandleSideLeft   = 1 << 2,
    ECSelectionHandleSideBottom = 1 << 3
};
typedef NSUInteger ECSelectionHandleSide;

@interface ECSelectionHandleView : UIView {
@private
    UIPanGestureRecognizer *dragRecognizer;
//    CGPoint dragStartPoint;
}

@property (nonatomic, assign) id<ECSelectionHandleViewDelegate> delegate;
@property (nonatomic) ECSelectionHandleSide side;

- (void)applyToRect:(CGRect)rect;

@end

//
//  ECTextOverlayLayer.h
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ECTextOverlayStyle.h"
#import "ECTextOverlay.h"
#import "ECTextLayer.h"

@interface ECTextOverlayLayer : CALayer {
@protected
    NSArray *overlayRects;
}

/// The style to apply to the overlay.
@property (nonatomic, retain) ECTextOverlayStyle *overlayStyle;

/// Create an overlay layer with an overlay style associated with it.
- (id)initWithOverlayStyle:(ECTextOverlayStyle *)aStyle;

/// Set the rects of the overlay and animate to display them. The array should contain \c ECTextOverlay objects.
- (void)setTextOverlays:(NSArray *)rects animate:(BOOL)doAnimation;

@end

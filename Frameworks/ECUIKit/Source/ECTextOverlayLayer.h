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
#import "ECRectSet.h"

@interface ECTextOverlayLayer : CALayer

#pragma mark Creating Text Overlay Layers

/// Create an overlay layer with an overlay style associated with it.
- (id)initWithTextOverlayStyle:(ECTextOverlayStyle *)aStyle;

#pragma mark Stiling and Content of Layer

/// The style to apply to the overlay.
@property (nonatomic, retain) ECTextOverlayStyle *overlayStyle;

/// The \c ECRectSet to draw as overlays.
@property (nonatomic, retain) NSArray *overlayRectSets;

@end

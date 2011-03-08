//
//  MyClass.h
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ECRectSet.h"

@interface ECTextOverlay : NSObject 

/// The rect of the overlay. If rectSet is present, this property returns the bounds of rectSet.
@property (nonatomic) CGRect rect;

/// Te set of rects of the overlay.
@property (nonatomic, retain) ECRectSet *rectSet;

/// Indicates if the overlay should be considered alternative.
@property (nonatomic, getter = isAlternative) BOOL alternative;

/// Initialize a text overlay with it's rect property.
- (id)initWithRect:(CGRect)aRect alternative:(BOOL)alt;

/// Initialize a text overlay with it's rectSet property.
- (id)initWithRectSet:(ECRectSet *)aRectSet alternative:(BOOL)alt;

/// Create a text overlay with it's rect property.
+ (id)textOverlayWithRect:(CGRect)aRect alternative:(BOOL)alt;

/// Create a text overlay with it's rectSet property. 
+ (id)textOverlayWithRectSet:(ECRectSet *)aRectSet alternative:(BOOL)alt;

@end

//
//  MyClass.h
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface ECTextOverlay : NSObject 

/// The rect of the overlay.
@property (nonatomic) CGRect rect;

/// Indicates if the overlay should be considered alternative.
@property (nonatomic, getter = isAlternative) BOOL alternative;

/// Initialize a text overlay and it's properties.
- (id)initWithRect:(CGRect)aRect alternative:(BOOL)alt;

/// Create a text overlay with it's properties.
+ (id)textOverlayWithRect:(CGRect)aRect alternative:(BOOL)alt;

@end

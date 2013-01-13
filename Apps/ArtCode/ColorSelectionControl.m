//
//  ColorSelectionControl.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ColorSelectionControl.h"
#import "UIColor+AppStyle.h"
#import "UIImage+AppStyle.h"

@interface ColorSelectionControl ()

@end

@implementation ColorSelectionControl

- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
  if (!self) return nil;
  self.colors = @[[UIColor styleForegroundColor],
		[UIColor colorWithRed:255./255. green:106./255. blue:89./255. alpha:1],
		[UIColor colorWithRed:255./255. green:184./255. blue:62./255. alpha:1],
		[UIColor colorWithRed:237./255. green:233./255. blue:68./255. alpha:1],
		[UIColor colorWithRed:168./255. green:230./255. blue:75./255. alpha:1],
		[UIColor colorWithRed:93./255. green:157./255. blue:255./255. alpha:1]];
  return self;
}

- (void)setColors:(NSArray *)colors {
	_colors = colors;
	[self removeAllSegments];
	[colors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger idx, BOOL *stop) {
		[self insertSegmentWithImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(12, 22) color:color] atIndex:idx animated:NO];
	}];
	// Adjust selected color
	if (self.selectedSegmentIndex >= (NSInteger)colors.count) {
		self.selectedSegmentIndex = 0;
	} else if (self.selectedSegmentIndex >= 0) {
		self.selectedColor = colors[self.selectedSegmentIndex];
	}
}

- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents {
	if (controlEvents == UIControlEventValueChanged) {
		self.selectedColor = self.colors[self.selectedSegmentIndex];
	}
	[super sendActionsForControlEvents:controlEvents];
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex {
	if (selectedSegmentIndex == self.selectedSegmentIndex)
		return;
	
	self.selectedColor = self.colors[selectedSegmentIndex];
	[super setSelectedSegmentIndex:selectedSegmentIndex];
}

- (void)setSelectedColor:(UIColor *)selectedColor {
	if ([selectedColor isEqual:self.selectedColor])
		return;
	
	NSUInteger colorIndex = [self.colors indexOfObject:selectedColor];
	if (colorIndex == NSNotFound)
		colorIndex = 0;
	
	_selectedColor = selectedColor;
	[super setSelectedSegmentIndex:colorIndex];
}

@end

//
//  ECRectSet.h
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

/// An immutable collection of CGRect
@interface ECRectSet : NSObject <NSCopying, NSMutableCopying> {
@protected
    CGRect *buffer;
    CGRect bounds;
    NSUInteger count;
    NSUInteger capacity;
}

#pragma mark Create RectSets

- (id)init;
- (id)initWithRect:(CGRect)rect;
- (id)initWithRects:(ECRectSet *)rects;
+ (id)rectSet;
+ (id)rectSetWithRect:(CGRect)rect;

#pragma mark Getting Set Informations

/// Return the union of all the CGRect in the set.
@property (nonatomic, readonly) CGRect bounds;

/// Get the number of CGRect in the set.
@property (nonatomic, readonly) NSUInteger count;

#pragma mark Utility Methods on RectSet

/// Enumerate all the CGRect in the set with the provided block.
- (void)enumerateRectsUsingBlock:(void (^)(CGRect rect, BOOL *stop))block;

/// Convinience function to add all the CGRect to a graphic context's path.
- (void)addRectsToContext:(CGContextRef)context;

/// Get, if presemt, the rect in the set that is at the top left.
- (CGRect)topLeftRect;

/// Get, if present, the rect in the set that is at the bottom right.
- (CGRect)bottomRightRect;

@end

/// Mutable version of \c ECRectSet
@interface ECMutableRectSet : ECRectSet

#pragma mark Create Mutable RectSet

- (id)initWithCapacity:(NSUInteger)cap;
+ (id)rectSetWithCapacity:(NSUInteger)cap;

#pragma mark Editing the Set Content

- (void)addRect:(CGRect)rect;
- (void)addRects:(ECRectSet *)rects;
- (void)removeRect:(CGRect)rect;
- (void)removeAllRects;

@end

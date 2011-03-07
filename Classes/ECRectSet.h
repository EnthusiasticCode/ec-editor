//
//  ECRectSet.h
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

// TODO comment this
@interface ECRectSet : NSObject <NSCopying, NSMutableCopying> {
@protected
    CGRect *buffer;
    CGRect bounds;
    NSUInteger count;
    NSUInteger capacity;
}

@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) NSUInteger count;

- (id)init;
- (id)initWithRect:(CGRect)rect;
- (id)initWithRects:(ECRectSet *)rects;
- (void)enumerateRectsUsingBlock:(void (^)(CGRect rect, BOOL *stop))block;

+ (id)rectSet;
+ (id)rectSetWithRect:(CGRect)rect;

@end

@interface ECMutableRectSet : ECRectSet

- (id)initWithCapacity:(NSUInteger)cap;

- (void)addRect:(CGRect)rect;
- (void)removeRect:(CGRect)rect;
- (void)removeAllRects;

+ (id)rectSetWithCapacity:(NSUInteger)cap;

@end

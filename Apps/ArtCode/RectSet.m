//
//  RectSet.m
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RectSet.h"

@implementation RectSet {
@protected
	CGRect *_buffer;
	CGRect _bounds;
	NSUInteger _count;
	NSUInteger _capacity;
}

- (CGRect)bounds {
	if (CGRectIsNull(_bounds)) {
		for (NSUInteger i = 0; i < _count; ++i) {
			_bounds = CGRectUnion(_bounds, _buffer[i]);
		}
	}
	return _bounds;
}

- (NSUInteger)count {
	return _count;
}

- (id)init {
	self = [super init];
	if (self == nil) return nil;
	
	_bounds = CGRectNull;
	
	return self;
}

- (id)initWithRect:(CGRect)rect {
	self = [self init];
	if (self == nil) return nil;
	
	_buffer = (CGRect *)malloc(sizeof(CGRect));
	*_buffer = rect;
	_count = _capacity = 1;
	
	return self;
}

- (id)initWithRects:(RectSet *)rects {
	self = [self init];
	if (self == nil) return nil;
	
	_count = _capacity = rects.count;
	_buffer = (CGRect *)malloc(_count * sizeof(CGRect));
	memcpy(_buffer, rects->_buffer, _count * sizeof(CGRect));
	
	return self;
}

- (void)dealloc {
	free(_buffer);
}

- (void)enumerateRectsUsingBlock:(void (^)(CGRect, BOOL *))block {
	BOOL stop = NO;
	for (NSUInteger i = 0; i < _count; ++i) {
		block(_buffer[i], &stop);
		if (stop) break;
	}
}

- (CGRect)topLeftRect {
	// TODO: check for proper return
	return _count ? _buffer[0] : CGRectNull;
}

- (CGRect)bottomRightRect {
	return _count ? _buffer[_count - 1] : CGRectNull;
}

- (void)addRectsToContext:(CGContextRef)context {
	CGContextAddRects(context, _buffer, _count);
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
	return [[MutableRectSet alloc] initWithRects:self];
}

+ (id)rectSet {
	return [[self alloc] init];
}

+ (id)rectSetWithRect:(CGRect)rect {
	return [[self alloc] initWithRect:rect];
}

@end


@implementation MutableRectSet

- (id)initWithCapacity:(NSUInteger)cap {
	self = [super init];
	if (self == nil) return nil;

	_capacity = cap;
	_buffer = (CGRect *)malloc(cap * sizeof(CGRect));
	
	return self;
}

- (void)addRect:(CGRect)rect {
	// TODO: guarantee single rect
	NSUInteger newCount = _count + 1;
	if (_capacity <= _count) {
		_buffer = (CGRect *)realloc(_buffer, newCount * sizeof(CGRect));
		_capacity = newCount;
	}
	_buffer[_count] = rect;
	_count = newCount;
}

- (void)addRects:(RectSet *)rects {
	if (!rects || !rects.count) return;
	
	if (_capacity - _count < rects.count) {
		_capacity = _count + rects.count;
		_buffer = (CGRect *)realloc(_buffer, _capacity * sizeof(CGRect));
	}
	
	memcpy(&_buffer[_count], rects->_buffer, rects.count * sizeof(CGRect));
	_count += rects.count;
	
	// TODO: calculate bounds?
}

- (void)removeRect:(CGRect)rect {
	for (NSUInteger i = 0; i < _count; ++i) {
		if (CGRectEqualToRect(_buffer[i], rect)) {
			memmove(&_buffer[i], &_buffer[i + 1], (_count - i) * sizeof(CGRect));
			--_count;
			_bounds = CGRectNull;
			return;
		}
	}
}

- (void)removeAllRects {
	_count = 0;
}

- (id)copyWithZone:(NSZone *)zone {
	return [[RectSet alloc] initWithRects:self];
}

+ (id)rectSetWithCapacity:(NSUInteger)cap {
	return [[self alloc] initWithCapacity:cap];
}

@end

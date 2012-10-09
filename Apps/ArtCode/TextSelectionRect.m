//
//  TextSelectionRect.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 09/10/12.
//
//

#import "TextSelectionRect.h"

@implementation TextSelectionRect

@synthesize rect = _rect, range = _range, containsStart = _containsStart, containsEnd = _containsEnd;

- (id)initWithRect:(CGRect)rect textRange:(UITextRange *)range isStart:(BOOL)isStart isEnd:(BOOL)isEnd {
  self = [super init];
  if (!self) {
    return nil;
  }
  _rect = rect;
  _range = range;
  _containsStart = isStart;
  _containsEnd = isEnd;
  return self;
}

- (UITextWritingDirection)writingDirection {
  return UITextWritingDirectionLeftToRight;
}

- (BOOL)isVertical {
  return NO;
}

@end

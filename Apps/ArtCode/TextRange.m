//
//  TextRange.m
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextRange.h"
#import "TextPosition.h"


@implementation TextRange

#pragma mark Properties

- (UITextPosition *)start
{
  return _start;
}

- (UITextPosition *)end
{
  return _end;
}

- (NSRange)range
{
  NSUInteger s = _start.index;
  NSUInteger e = _end.index;
  if (s > e) 
    return (NSRange){e, s - e};
  return (NSRange){s, e - s};
}

- (CFRange)CFRange
{
  return (CFRange){(CFIndex)_start.index, (CFIndex)(_end.index - _start.index)};
}

- (id)initWithStart:(TextPosition*)aStart end:(TextPosition*)aEnd
{
  //    assert([aStart isKindOfClass:[TextPosition class]]);
  //    assert([aEnd isKindOfClass:[TextPosition class]]);
  if((self = [super init]))
  {
    _start = aStart;
    _end = aEnd;
  }
  return self;
}

- (id)initWithRange:(NSRange)characterRange
{
  TextPosition *st = [[TextPosition alloc] initWithIndex:characterRange.location];
  TextPosition *en;
  
  if (characterRange.length == 0)
  {
    en = st;
  }
  else 
  {
    en = [[TextPosition alloc] initWithIndex:(characterRange.location + characterRange.length)];
  }
  
  self = [self initWithStart:st end:en];
  
  
  return self;
}


- (TextRange*)rangeIncludingPosition:(TextPosition*)p
{
  if ([p compare:_start] == NSOrderedAscending)
    return [[self.class alloc] initWithStart:p end:_end];
  if ([p compare:_end] == NSOrderedDescending)
    return [[self.class alloc] initWithStart:_start end:p];
  
  return self;
}

- (BOOL)includesPosition:(TextPosition*)p
{
  if ([_start compare:p] == NSOrderedDescending)
    return NO;
  if ([_end compare:p] == NSOrderedAscending)
    return NO;
  return YES;
}

- (id)copyWithZone:(NSZone *)z
{
  return self;
}

- (BOOL)isEmpty
{
  return ( [_start compare:_end] == NSOrderedSame );
}

- (BOOL)isEqual:(id)other
{
  if (![other isKindOfClass:self.class])
    return NO;
  
  TextRange *otherRange = (TextRange *)other;
  
  return ([_start compare:otherRange.start] == NSOrderedSame) && ([_end compare:otherRange.end] == NSOrderedSame);
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@..%@", [_start description], [_end description]];
}

#pragma mark -
#pragma mark Class methods

+ (id)textRangeWithRange:(NSRange)range
{
  return [[self alloc] initWithRange:range];
}

@end

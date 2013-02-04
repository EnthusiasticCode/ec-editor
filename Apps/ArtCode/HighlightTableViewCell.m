//
//  HighlightTableViewCell.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HighlightTableViewCell.h"
#import <CoreText/CoreText.h>


@interface HighlightView : UIView

@property (nonatomic, strong) NSAttributedString *attributedText;
@property (nonatomic, strong) NSIndexSet *highlightedCharacters;
@property (nonatomic, strong) UIColor *highlightedBackgroundColor;

@end


@implementation HighlightTableViewCell {
  HighlightView *_highlightView;
}

@synthesize textLabelHighlightedCharactersBackgroundColor;

- (NSIndexSet *)textLabelHighlightedCharacters
{
  return _highlightView.highlightedCharacters;
}

- (void)setTextLabelHighlightedCharacters:(NSIndexSet *)value
{
  if (value == _highlightView.highlightedCharacters)
    return;
  if (value.count == 0)
  {
    [_highlightView removeFromSuperview];
  }
  else
  {
    if (!_highlightView)
    {
      _highlightView = [[HighlightView alloc] initWithFrame:self.textLabel.frame];
      _highlightView.highlightedBackgroundColor = textLabelHighlightedCharactersBackgroundColor;
    }
    _highlightView.highlightedCharacters = value;
    [self.contentView insertSubview:_highlightView belowSubview:self.textLabel];
    self.textLabel.backgroundColor = UIColor.clearColor;
  }
  [self setNeedsLayout];
}

- (void)setTextLabelHighlightedCharactersBackgroundColor:(UIColor *)value
{
  if (value == textLabelHighlightedCharactersBackgroundColor)
    return;
  textLabelHighlightedCharactersBackgroundColor = value;
  _highlightView.highlightedBackgroundColor = value;
  [self setNeedsLayout];
}

- (NSAttributedString *)_attributedTitleText
{
	if (self.textLabel.text == nil) return [[NSAttributedString alloc] init];
  CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.textLabel.font.fontName, self.textLabel.font.pointSize, NULL);
  NSAttributedString *result = [[NSAttributedString alloc] 
                                initWithString:self.textLabel.text 
                                attributes:@{(__bridge id)kCTForegroundColorAttributeName: (__bridge id)self.textLabel.textColor.CGColor, 
                                            (__bridge id)kCTFontAttributeName: (__bridge id)font}];
  CFRelease(font);
  return result;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self)
    return nil;
  self.textLabelHighlightedCharactersBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  if (![_highlightView superview])
    return;
  
  _highlightView.attributedText = [self _attributedTitleText];
  _highlightView.frame = self.textLabel.frame;
}

@end


@implementation HighlightView

@synthesize attributedText, highlightedCharacters, highlightedBackgroundColor;

- (id)initWithFrame:(CGRect)frame
{
  if (!(self = [super initWithFrame:frame]))
    return nil;
  self.contentMode = UIViewContentModeRedraw;
  self.backgroundColor = UIColor.clearColor;
  return self;
}

- (void)drawRect:(CGRect)rect
{
  if (highlightedCharacters.count == 0)
    return;
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect bounds = [self bounds];
  
  [self.highlightedBackgroundColor setFill];
  
  
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)[self attributedText]);
  CGPathRef path = CGPathCreateWithRect(bounds, NULL);
  CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [self.attributedText length]), path, NULL);
  
  CFArrayRef lines = CTFrameGetLines(frame);
  CFIndex lineCount = CFArrayGetCount(lines);
  //ASSERT(lineCount <= 1 && "Not designed for multiline");
  for (CFIndex i = 0; i < lineCount; ++i)
  {
    CTLineRef line = CFArrayGetValueAtIndex(lines, i);
    CFRange lineRange = CTLineGetStringRange(line);
    CGFloat ascent, descent;
    CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
    [highlightedCharacters enumerateRangesInRange:NSMakeRange(lineRange.location, lineRange.length) options:0 usingBlock:^(NSRange range, BOOL *stop) {
      CGFloat startOffset = CTLineGetOffsetForStringIndex(line, range.location, NULL);
      CGFloat endOffset = CTLineGetOffsetForStringIndex(line, NSMaxRange(range), NULL);
      CGContextFillRect(context, CGRectMake(startOffset, CGRectGetMidY(bounds) - (ascent + descent) / 2.0, endOffset - startOffset, ascent + descent));
    }];
  }
  
  CFRelease(frame);
  CFRelease(path);
  CFRelease(framesetter);
  
  [super drawRect:rect];
}

- (void)setAttributedText:(NSAttributedString *)value
{
  attributedText = value;
  [self setNeedsDisplay];
}

- (void)setHighlightedCharacters:(NSIndexSet *)value
{
  highlightedCharacters = value;
  [self setNeedsDisplay];
}

- (void)setHighlightedBackgroundColor:(UIColor *)value
{
  highlightedBackgroundColor = value;
  [self setNeedsDisplay];
}

@end

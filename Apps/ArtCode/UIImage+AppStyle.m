//
//  UIImage+AppStyle.m
//  ACUI
//
//  Created by Nicola Peduzzi on 18/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImage+AppStyle.h"
#import "UIColor+AppStyle.h"
#import "UIImage+BlockDrawing.h"
#import <CoreText/CoreText.h>

@implementation UIImage (AppStyle)

+ (UIImage *)styleBackgroundImageWithColor:(UIColor *)color 
                               borderColor:(UIColor *)borderColor 
                                    insets:(UIEdgeInsets)borderInsets 
                                 arrowSize:(CGSize)arrowSize 
                           roundingCorners:(UIRectCorner)cornersToRound
{
  CGFloat radius = 3;
  CGFloat leftArrow = (arrowSize.width < 0. ? -arrowSize.width : 0);
  CGFloat rightArrow = (arrowSize.width > 0. ? arrowSize.width : 0); 
  CGSize imageSize = CGSizeMake(3 + 2 + 3 + leftArrow + rightArrow + borderInsets.left + borderInsets.right, 
                                arrowSize.height ? arrowSize.height : 3 + 2 + 3 + borderInsets.top + borderInsets.bottom);
  return [[UIImage imageWithSize:imageSize block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    CGMutablePathRef path = CGPathCreateMutable();
    
    rect = UIEdgeInsetsInsetRect(rect, borderInsets);
    rect = CGRectInset(rect, .5, .5);
    
    // Build path
    if (arrowSize.width == 0.)
    {
      CGPathAddPath(path, NULL, [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:cornersToRound cornerRadii:CGSizeMake(radius, radius)].CGPath);
    }
    else
    {            
      CGRect innerRect = CGRectInset(rect, radius, radius);
      
      CGFloat outside_right = rect.origin.x + rect.size.width;
      CGFloat outside_bottom = rect.origin.y + rect.size.height;
      CGFloat inside_left = innerRect.origin.x + leftArrow;
      CGFloat inside_right = innerRect.origin.x + innerRect.size.width - rightArrow;
      CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
      
      CGFloat inside_top = innerRect.origin.y;
      CGFloat outside_top = rect.origin.y;
      CGFloat outside_left = rect.origin.x;
      
      //        CGFloat middle_width = outside_right / 2.0;
      CGFloat middle_height = outside_bottom / 2.0;
      
      // TODO: No top arrow for now
      CGPathMoveToPoint(path, NULL, inside_left, outside_top);
      CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
      
      // Right arrow
      if (rightArrow > 0) 
      {
        CGFloat arrow_size = rightArrow * 0.4;
        CGFloat inside_arrow = inside_right + rightArrow + radius * 0.7;
        CGFloat arrow_midtop = middle_height - radius / 2;
        CGFloat arrow_midbottom = arrow_midtop + radius;
        CGPathAddCurveToPoint(path, NULL,
                              inside_right + arrow_size, outside_top, 
                              inside_arrow, arrow_midtop, 
                              inside_arrow, arrow_midtop);
        CGPathAddCurveToPoint(path, NULL,
                              outside_right, middle_height, 
                              outside_right, middle_height, 
                              inside_arrow, arrow_midbottom);
        CGPathAddCurveToPoint(path, NULL,
                              inside_arrow, arrow_midbottom, 
                              inside_right + arrow_size, outside_bottom, 
                              inside_right, outside_bottom);
      }
      else
      {
        CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, radius);
        CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
        CGPathAddArcToPoint(path, NULL, outside_right, outside_bottom, inside_right, outside_bottom, radius);
      }
      
      // TODO: no bottom arrow
      CGPathAddLineToPoint(path, NULL, inside_left, outside_bottom);
      
      // Left arrow
      if (leftArrow > 0) 
      {
        CGFloat arrow_size = leftArrow * 0.4;
        CGFloat inside_arrow = inside_left - leftArrow - radius * 0.7;
        CGFloat arrow_midtop = middle_height - radius / 2;
        CGFloat arrow_midbottom = arrow_midtop + radius;
        CGPathAddCurveToPoint(path, NULL,
                              inside_left - arrow_size, outside_bottom,
                              inside_arrow, arrow_midbottom,
                              inside_arrow, arrow_midbottom);
        CGPathAddCurveToPoint(path, NULL,
                              outside_left, middle_height, 
                              outside_left, middle_height, 
                              inside_arrow, arrow_midtop);
        CGPathAddCurveToPoint(path, NULL, 
                              inside_arrow, arrow_midtop, 
                              inside_left - arrow_size, outside_top, 
                              inside_left, outside_top);
      }
      else
      {
        CGPathAddArcToPoint(path, NULL, outside_left, outside_bottom, outside_left, inside_bottom, radius);
        CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
        CGPathAddArcToPoint(path, NULL, outside_left, outside_top, inside_left, outside_top, radius);
      }
      
      CGPathCloseSubpath(path);
    }
    
    // Draw
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, borderColor.CGColor);
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);        
    
    CGPathRelease(path);
  }] resizableImageWithCapInsets:UIEdgeInsetsMake(arrowSize.height ? 0 : borderInsets.top + 3, 
                                                  borderInsets.left + 3 + leftArrow, 
                                                  arrowSize.height ? 0 : borderInsets.bottom + 3, 
                                                  borderInsets.right + 3 + rightArrow)];
}

+ (UIImage *)styleBackgroundImageWithColor:(UIColor *)color borderColor:(UIColor *)borderColor
{
  return [UIImage styleBackgroundImageWithColor:color borderColor:borderColor insets:UIEdgeInsetsZero arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners];
}

+ (UIImage *)styleProjectImageWithSize:(CGSize)size labelColor:(UIColor *)labelColor
{
  if (!labelColor)
    labelColor = [UIColor styleForegroundColor];
  return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    // Removing one pixel to add shadow
    rect.size.height -= scale;
    
    CGRect orect = rect;        
    CGFloat marginLeft = ceilf(rect.size.width / 10);
    rect.origin.x += marginLeft;
    rect.size.width -= marginLeft;
    
    CGFloat mid = orect.origin.x + ceilf(orect.size.width / 2);
    CGFloat bspaceInner = orect.origin.y + ceilf(orect.size.height * 0.61);
    CGFloat bspaceOutter = orect.origin.y + ceilf(orect.size.height * 0.69);
    
    //
    // Document path
    CGFloat line = ceilf(rect.size.height / 7.0);
    CGFloat corner = ceilf(rect.size.height / 4.0);
    CGRect innerRect = CGRectInset(rect, line, line);
    CGMutablePathRef docPath = CGPathCreateMutable();
    
    // Top line
    CGPathAddRect(docPath, NULL, (CGRect){ 
      { mid, rect.origin.y } , 
      { mid - corner, line } 
    });
    // Left line
    CGPathAddRect(docPath, NULL, (CGRect){ 
      { rect.origin.x, bspaceOutter }, 
      { line, rect.size.height - bspaceOutter } 
    });
    CGPathMoveToPoint(docPath, NULL, rect.origin.x, bspaceOutter);
    CGPathAddLineToPoint(docPath, NULL, rect.origin.x + line, bspaceInner);
    CGPathAddLineToPoint(docPath, NULL, rect.origin.x + line, bspaceOutter);
    CGPathCloseSubpath(docPath);
    // Right line
    CGPathAddRect(docPath, NULL, (CGRect){ 
      { innerRect.origin.x + innerRect.size.width, rect.origin.y + corner }, 
      { line, rect.size.height - corner } 
    });
    // Bottom line
    CGPathAddRect(docPath, NULL, (CGRect){ 
      { innerRect.origin.x, innerRect.origin.y + innerRect.size.height }, 
      { innerRect.size.width, line } 
    });
    // Corner
    CGFloat innerCorner = ceilf(corner * 1.3);
    CGPathMoveToPoint(docPath, NULL, rect.origin.x + rect.size.width - corner, rect.origin.y);
    CGPathAddLineToPoint(docPath, NULL, rect.origin.x + rect.size.width, rect.origin.y + corner);
    CGPathAddLineToPoint(docPath, NULL, innerRect.origin.x + innerRect.size.width, rect.origin.y + innerCorner);
    CGPathAddLineToPoint(docPath, NULL, rect.origin.x + rect.size.width - innerCorner, rect.origin.y + line);
    CGPathCloseSubpath(docPath);
    
    //
    // Bookmark Path        
    CGFloat bookmarkWidth = orect.origin.x + ceilf(orect.size.width * 0.39) + 0.5;
    CGFloat bookmarkHeight = orect.origin.y + ceilf(orect.size.height * 0.63);
    CGFloat bookmarkInnerHeight = orect.origin.y + ceilf(orect.size.height * 0.53);
    
    CGMutablePathRef bookmarkPath = CGPathCreateMutable();
    CGPathMoveToPoint(bookmarkPath, NULL, orect.origin.x + 0.5, orect.origin.y + 0.5);
    CGPathAddLineToPoint(bookmarkPath, NULL, bookmarkWidth, orect.origin.y + 0.5);
    CGPathAddLineToPoint(bookmarkPath, NULL, bookmarkWidth, bookmarkHeight);
    CGPathAddLineToPoint(bookmarkPath, NULL, (orect.origin.x + bookmarkWidth) / 2.0, bookmarkInnerHeight);
    CGPathAddLineToPoint(bookmarkPath, NULL, orect.origin.x + 0.5, bookmarkHeight);
    CGPathCloseSubpath(bookmarkPath);
    
    // Draw shadow
    CGContextSetFillColorWithColor(ctx, [UIColor styleForegroundShadowColor].CGColor);
    CGContextSaveGState(ctx);
    {
      CGContextTranslateCTM(ctx, 0, scale);
      CGContextAddPath(ctx, docPath);
      CGContextAddPath(ctx, bookmarkPath);
      CGContextFillPath(ctx);
    }
    CGContextRestoreGState(ctx);
    
    // Draw document
    CGContextSetFillColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
    CGContextAddPath(ctx, docPath);
    CGContextFillPath(ctx);
    
    // Draw bookmark
    CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
    CGContextSetFillColorWithColor(ctx, labelColor.CGColor);
    CGContextSetLineWidth(ctx, scale);
    
    CGContextAddPath(ctx, bookmarkPath);
    CGContextFillPath(ctx);
    
    CGContextAddPath(ctx, bookmarkPath);
    CGContextStrokePath(ctx);
    
    CGPathRelease(docPath);
    CGPathRelease(bookmarkPath);
  }];
}

+ (UIImage *)styleProjectLabelImageWithSize:(CGSize)size color:(UIColor *)color {
  if (!color)
    color = [UIColor styleForegroundColor];
  return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    // Removing one point to add shadow
    rect.size.height -= scale;
    
    // Bookmark Path        
    CGFloat bookmarkWidth = rect.size.width - 0.5;
    CGFloat bookmarkHeight = rect.size.height - 0.5;
    CGFloat bookmarkInnerHeight = ceilf(bookmarkHeight * 0.7);
    
    CGMutablePathRef bookmarkPath = CGPathCreateMutable();
    CGPathMoveToPoint(bookmarkPath, NULL, rect.origin.x + 0.5, rect.origin.y + 0.5);
    CGPathAddLineToPoint(bookmarkPath, NULL, bookmarkWidth, rect.origin.y + 0.5);
    CGPathAddLineToPoint(bookmarkPath, NULL, bookmarkWidth, bookmarkHeight);
    CGPathAddLineToPoint(bookmarkPath, NULL, (rect.origin.x + bookmarkWidth) / 2.0, bookmarkInnerHeight);
    CGPathAddLineToPoint(bookmarkPath, NULL, rect.origin.x + 0.5, bookmarkHeight);
    CGPathCloseSubpath(bookmarkPath);
    
    // Draw bookmark
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -scale), 0, [UIColor styleForegroundShadowColor].CGColor);
    CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, scale);
    
    CGContextAddPath(ctx, bookmarkPath);
    CGContextFillPath(ctx);
    
    CGContextSetShadow(ctx, CGSizeZero, 0);
    CGContextAddPath(ctx, bookmarkPath);
    CGContextStrokePath(ctx);
    
    CGPathRelease(bookmarkPath);
  }];
}

+ (UIImage *)styleDocumentImageWithSize:(CGSize)size color:(UIColor *)color text:(NSString *)text
{
  // Account for shadow
  size.height += 1;
  return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    // Resize for shadow and margins
    rect.size.height -= 1;
    rect = CGRectInset(rect, roundf(rect.size.width / 20.), 0);
    CGFloat strokeWidth = ceilf(0.14 * rect.size.height);
    CGFloat strokeWidth_2 = strokeWidth / 2.;
    rect = CGRectInset(rect, strokeWidth_2, strokeWidth_2);
    
    // Create path
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat rectMaxX = CGRectGetMaxX(rect);
    CGFloat rectMaxY = CGRectGetMaxY(rect);
    CGFloat foldSize = roundf(rect.size.height / 4.);
    
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, rectMaxX - foldSize, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, rectMaxX, rect.origin.y + foldSize);
    CGPathAddLineToPoint(path, NULL, rectMaxX, rectMaxY);
    CGPathAddLineToPoint(path, NULL, rect.origin.x, rectMaxY);
    CGPathCloseSubpath(path);
    
    // Draw
    CGContextSaveGState(ctx);
    {
      CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, [UIColor whiteColor].CGColor);
      CGContextAddPath(ctx, path);
      CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
      CGContextSetLineWidth(ctx, strokeWidth);
      CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
    
    if (color && strokeWidth > 2)
    {
      CGContextAddPath(ctx, path);
      CGContextSetStrokeColorWithColor(ctx, color.CGColor);
      CGContextSetLineWidth(ctx, strokeWidth - 2);
      CGContextStrokePath(ctx);
    }
    
    // Label
    if (text)
    {
      CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, [UIColor whiteColor].CGColor);
      
      CGFloat fontSize = (rect.size.width - strokeWidth);
      if ([text length] > 1)
        fontSize /= 2.;
      CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)@"Courier-Bold", fontSize, NULL);
      NSAttributedString *attributedText = 
      [[NSAttributedString alloc] initWithString:text 
                                      attributes:@{(id)kCTFontAttributeName: (__bridge id)font}];
      
      CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedText);
      CGFloat lineDescent;
      CGFloat lineWidth = CTLineGetTypographicBounds(line, NULL, &lineDescent, NULL);
      if ([text length] == 1)
      {
        lineWidth += 1;
        lineDescent = 0;
      }
      
      //            CTRunRef run = CFArrayGetValueAtIndex(CTLineGetGlyphRuns(line), 0);
      //            CFIndex runCount = CTRunGetGlyphCount(run);
      //            const CGGlyph *glyphs = CTRunGetGlyphsPtr(run);
      //            CGRect glyphRect;
      //            CGFloat lineWidth = 0, lineHeight = 0;
      //            do {
      //                CTFontGetBoundingRectsForGlyphs(font, kCTFontDefaultOrientation, glyphs, &glyphRect, 1);
      //                lineWidth += glyphRect.size.width;
      //                lineHeight = MAX(lineHeight, glyphRect.size.height);
      //            } while (--runCount > 0 && glyphs++);
      
      CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1, -1));
      CGContextSetTextPosition(ctx, rectMaxX - strokeWidth_2 - lineWidth, rectMaxY - strokeWidth_2 - lineDescent - 1);
      CTLineDraw(line, ctx);
      
      CFRelease(line);
      CFRelease(font);
    }
    
    // Cleanup
    CGPathRelease(path);
  }];
}

+ (UIImage *)styleDocumentImageWithFileExtension:(NSString *)extension
{
  static NSCache *documentImageCache = nil;
  if (!documentImageCache)
    documentImageCache = [[NSCache alloc] init];
  UIImage *documentImage = [documentImageCache objectForKey:extension];
  if (documentImage)
    return documentImage;
  
  UIColor *color = nil;
  if ([extension isEqualToString:@"h"])
    color = [UIColor colorWithRed:193.0/255.0 green:39.0/255.0 blue:45.0/255.0 alpha:1.0];
  else if ([extension isEqualToString:@"m"])
    color = [UIColor colorWithRed:0.0/255.0 green:113.0/255.0 blue:188.0/255.0 alpha:1.0];
  else if ([extension rangeOfString:@"htm"].location != NSNotFound)
    color = [UIColor colorWithRed:205.0/255.0 green:70.0/255.0 blue:48.0/255.0 alpha:1.0];
  documentImage = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) color:color text:extension];
  [documentImageCache setObject:documentImage forKey:extension];
  return documentImage;
}

+ (UIImage *)styleGroupImageWithSize:(CGSize)size
{
  size.height += 1;
  return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    rect.size.height -= 1;
    CGFloat strokeWidth = ceilf(0.14 * rect.size.height);
    CGFloat strokeWidth_2 = strokeWidth / 2.;
    rect = CGRectInset(rect, strokeWidth_2, strokeWidth_2);
    
    // Create path
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat rectMaxX = CGRectGetMaxX(rect);
    CGFloat rectMaxY = CGRectGetMaxY(rect);
    CGRect angleRect = CGRectMake(rect.origin.x + rect.size.width * .42, rect.origin.y, rect.size.width * .18, roundf(rect.size.height * .18));
    
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, angleRect.origin.x, angleRect.origin.y);
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(angleRect), CGRectGetMaxY(angleRect));
    CGPathAddLineToPoint(path, NULL, rectMaxX, CGRectGetMaxY(angleRect));
    CGPathAddLineToPoint(path, NULL, rectMaxX, rectMaxY);
    CGPathAddLineToPoint(path, NULL, rect.origin.x, rectMaxY);
    CGPathCloseSubpath(path);
    
    // Draw
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, [UIColor whiteColor].CGColor);
    CGContextAddPath(ctx, path);
    CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
    CGContextSetLineWidth(ctx, strokeWidth);
    CGContextStrokePath(ctx);
    
    CGPathRelease(path);
  }];
}

+ (UIImage *)styleTableDisclosureImageWithColor:(UIColor *)color shadowColor:(UIColor *)shadowColor
{
  CGSize size = CGSizeMake(9, shadowColor ? 14 : 13);
  return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    // Account for shadow
    if (shadowColor)
      rect.size.height -= 1;
    
    // (x,y) is the tip of the arrow
    CGFloat x = CGRectGetMaxX(rect) - 2;
    CGFloat y = CGRectGetMidY(rect);
    const CGFloat R = 4.5;
    
    // Create 
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, x-R, y-R);
    CGPathAddLineToPoint(path, NULL, x, y);
    CGPathAddLineToPoint(path, NULL, x-R, y+R);
    
    // Set properties
    CGContextSetLineCap(ctx, kCGLineCapSquare);
    CGContextSetLineJoin(ctx, kCGLineJoinMiter);
    CGContextSetLineWidth(ctx, 3);
    
    // Draw body
    if (shadowColor)
      CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, shadowColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    
    // Clean up
    CGPathRelease(path);
  }];
}

+ (UIImage *)styleDisclosureArrowImageWithOrientation:(UIImageOrientation)orientation color:(UIColor *)color
{
  CGSize imageSize = (CGSize){ 14, 9 };
  if (orientation == UIImageOrientationLeft || orientation == UIImageOrientationRight)
    imageSize = (CGSize){ 9, 14 };
  return [UIImage imageWithSize:imageSize block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    CGAffineTransform transform;
    switch (orientation) {
      case UIImageOrientationUp: { transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI), -14, -9); break; }
      case UIImageOrientationLeft: { transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -9); break; }
      case UIImageOrientationRight: { transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -14, 0); break; }
      default: { transform = CGAffineTransformIdentity; break; }
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Create path
    CGPathMoveToPoint(path, &transform, 0, 0);
    CGPathAddLineToPoint(path, &transform, 6, 8);
    CGPathAddArcToPoint(path, &transform, 7, 9, 8, 8, 1);
    CGPathAddLineToPoint(path, &transform, 15, 0);
    CGPathCloseSubpath(path);
    
    // Draw
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    
    CGPathRelease(path);
  }];
}

+ (UIImage *)styleAddImageWithColor:(UIColor *)color shadowColor:(UIColor *)shadowColor
{
  return [UIImage imageWithSize:(CGSize){ 14, shadowColor ? 15 : 14 } block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    // Accounting for shadow
    if (shadowColor)
      rect.size.height -= 1;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat centerX = CGRectGetMidX(rect);
    CGFloat centerY = CGRectGetMidY(rect);
    
    CGPathMoveToPoint(path, NULL, rect.origin.x, centerY);
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(rect), centerY);
    
    CGPathMoveToPoint(path, NULL, centerX, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, centerX, CGRectGetMaxY(rect));
    
    CGContextSetLineCap(ctx, kCGLineCapButt);
    CGContextSetLineJoin(ctx, kCGLineJoinMiter);
    CGContextSetLineWidth(ctx, 4);
    
    if (shadowColor)
      CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, shadowColor.CGColor);
    
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    
    CGPathRelease(path);
  }];
}

+ (UIImage *)styleCloseImageWithColor:(UIColor *)color outlineColor:(UIColor *)outlineColor shadowColor:(UIColor *)shadowColor
{
  return [UIImage imageWithSize:(CGSize){16, shadowColor ? 17 : 16} block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    // Accounting for shadow
    if (shadowColor)
    {
      rect.size.height -= 1;
      CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, shadowColor.CGColor);
      CGContextBeginTransparencyLayer(ctx, NULL);
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect innerRect = CGRectInset(rect, 3, 3);
    
    CGPathMoveToPoint(path, NULL, innerRect.origin.x, innerRect.origin.y);
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(innerRect), CGRectGetMaxY(innerRect));
    CGPathMoveToPoint(path, NULL, CGRectGetMaxX(innerRect), innerRect.origin.y);
    CGPathAddLineToPoint(path, NULL, innerRect.origin.x, CGRectGetMaxY(innerRect));
    
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinMiter);
    
    if (outlineColor)
    {
      CGContextSetLineWidth(ctx, 4);
      CGContextSetStrokeColorWithColor(ctx, outlineColor.CGColor);
      CGContextAddPath(ctx, path);
      CGContextStrokePath(ctx);
    }
    
    CGContextSetLineWidth(ctx, 3);
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    
    if (shadowColor)
      CGContextEndTransparencyLayer(ctx);
    
    CGPathRelease(path);
  }];
}

+ (UIImage *)styleSymbolImageWithSize:(CGSize)size color:(UIColor *)color letter:(NSString *)letter
{
  return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    rect = CGRectInset(rect, .5, .5);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:2].CGPath;
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    
    CGContextSetFillColorWithColor(ctx, [color colorWithAlphaComponent:0.80].CGColor);
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    
    CGContextSetLineWidth(ctx, 0.4);
    CGContextSetTextDrawingMode(ctx, kCGTextFillStroke);
    CGContextSelectFont(ctx, "Helvetica-Bold", size.width - 1, kCGEncodingMacRoman);
    CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1, -1));
    CGSize letterSize = [letter sizeWithFont:[UIFont boldSystemFontOfSize:size.width - 1]];
    CGContextSetTextPosition(ctx, floorf((size.width - letterSize.width) / 2.) + .5, size.height - 2.5);
    
    CGContextShowText(ctx, [letter cStringUsingEncoding:NSUTF8StringEncoding], [letter lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
  }];
}

+ (UIImage *)styleSearchIconWithColor:(UIColor *)color shadowColor:(UIColor *)shadowColor
{
  CGSize size = CGSizeMake(16, shadowColor ? 17 : 16);
  return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
    if (shadowColor)
    {
      rect.size.height -= 1;
      CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, shadowColor.CGColor);
      CGContextBeginTransparencyLayer(ctx, NULL);
    }
    // 
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    //
    CGContextAddArc(ctx, rect.size.width - 6, 6, 5, 0, M_PI * 2, YES);
    CGContextSetLineWidth(ctx, 2);
    CGContextStrokePath(ctx);
    //
    CGContextMoveToPoint(ctx, 2, rect.size.height - 2);
    CGContextAddLineToPoint(ctx, 4.8, rect.size.height - 4.8);
    CGContextSetLineWidth(ctx, 4);
    CGContextStrokePath(ctx);
    //
    if (shadowColor)
      CGContextEndTransparencyLayer(ctx);
  }];
}

+ (UIImage *)styleCheckMarkImage
{
  static UIImage *_styleCheckMarkImage = nil;
  if (!_styleCheckMarkImage)
  {
    _styleCheckMarkImage = [UIImage imageWithSize:CGSizeMake(29, 29) block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
      CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
      
      CGContextAddArc(ctx, 29. / 2., 29. / 2., 10, -M_PI, M_PI, 0);
      CGContextSetLineWidth(ctx, 2);
      CGContextStrokePath(ctx);
      
      CGContextMoveToPoint(ctx, 9, 16);
      CGContextAddLineToPoint(ctx, 14, 20);
      CGContextAddLineToPoint(ctx, 20, 9);
      CGContextSetLineWidth(ctx, 3);
      CGContextStrokePath(ctx);
    }];
  }
  return _styleCheckMarkImage;
}

+ (UIImage *)styleReorderControlImage
{
  static UIImage *_styleReorderControlImage = nil;
  if (!_styleReorderControlImage)
  {
    _styleReorderControlImage = [UIImage imageWithSize:CGSizeMake(19, 17) block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
      CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 0, [UIColor whiteColor].CGColor);
      
      CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
      CGContextSetLineWidth(ctx, 4);
      
      CGFloat y = 2;
      for (NSUInteger i = 0; i < 3; ++i)
      {
        CGContextMoveToPoint(ctx, 0, y);
        CGContextAddLineToPoint(ctx, rect.size.width, y);
        y += 6;
      }
      
      CGContextStrokePath(ctx);
    }];
  }
  return _styleReorderControlImage;
}

+ (UIImage *)styleDeleteActivationImage
{
  static UIImage *_styleDeleteActivationImage = nil;
  if (!_styleDeleteActivationImage)
  {
    _styleDeleteActivationImage = [UIImage imageWithSize:CGSizeMake(29, 29) block:^(CGContextRef ctx, CGRect rect, CGFloat scale) {
      CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
      CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:200./255. green:8./255. blue:21./255. alpha:1].CGColor);
      
      CGContextAddArc(ctx, 29. / 2., 29. / 2., 11, -M_PI, M_PI, 0);
      CGContextFillPath(ctx);
      
      CGContextMoveToPoint(ctx, 8, 29. / 2.);
      CGContextAddLineToPoint(ctx, 21, 29. / 2.);
      CGContextSetLineWidth(ctx, 5);
      CGContextStrokePath(ctx);
    }];
  }
  return _styleDeleteActivationImage;
}

+ (UIImage *)styleNormalButtonBackgroundImageForControlState:(UIControlState)state
{
  static UIImage *images[2] = { nil, nil };
  switch (state) {
    case UIControlStateNormal:
      if (images[0] == nil)
        images[0] = [[UIImage imageNamed:@"topBar_ToolButton_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 10, 15, 10)];
      return images[0];
      
    default:
      if (images[1] == nil)
        images[1] = [[UIImage imageNamed:@"topBar_ToolButton_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 10, 15, 10)];
      return images[1];
  }
}

+ (UIImage *)styleBackButtonBackgroundImage
{
  static UIImage *_styleBackButtonBackgroundImage = nil;
  if (!_styleBackButtonBackgroundImage)
    _styleBackButtonBackgroundImage = [[UIImage imageNamed:@"topBar_BackButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 10)];
  return _styleBackButtonBackgroundImage;
}

+ (UIImage *)stylePopoverButtonBackgroundImage {
  static UIImage *_stylePopoverButtonBackgroundImage = nil;
  if (!_stylePopoverButtonBackgroundImage)
    _stylePopoverButtonBackgroundImage = [[UIImage imageNamed:@"popover_Button"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
  return _stylePopoverButtonBackgroundImage;
}

@end

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

@implementation UIImage (AppStyle)

+ (UIImage *)styleBackgroundImageWithColor:(UIColor *)color 
                               borderColor:(UIColor *)borderColor 
                                    insets:(UIEdgeInsets)borderInsets 
                                 arrowSize:(CGSize)arrowSize
{
    CGFloat radius = 3;
    CGFloat leftArrow = (arrowSize.width < 0. ? -arrowSize.width : 0);
    CGFloat rightArrow = (arrowSize.width > 0. ? arrowSize.width : 0); 
    CGSize imageSize = CGSizeMake(3 + 2 + 3 + leftArrow + rightArrow + borderInsets.left + borderInsets.right, 
                                  arrowSize.height ? arrowSize.height : 3 + 2 + 3 + borderInsets.top + borderInsets.bottom);
    return [[UIImage imageWithSize:imageSize block:^(CGContextRef ctx, CGRect rect) {
        CGMutablePathRef path = CGPathCreateMutable();
        
        rect = UIEdgeInsetsInsetRect(rect, borderInsets);
        rect = CGRectInset(rect, .5, .5);
        
        // Build path
        if (arrowSize.width == 0.)
        {
            CGPathAddPath(path, NULL, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius].CGPath);
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
            
            // TODO No top arrow for now
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
            
            // TODO no bottom arrow
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

+ (UIImage *)styleProjectImageWithSize:(CGSize)size labelColor:(UIColor *)labelColor
{
    return [UIImage imageWithSize:size block:^(CGContextRef ctx, CGRect rect) {
        // Removing one pixel to add shadow
        rect.size.height -= 1;
        
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
            CGContextTranslateCTM(ctx, 0, 1);
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
        CGContextSetLineWidth(ctx, 1);

        CGContextAddPath(ctx, bookmarkPath);
        CGContextFillPath(ctx);
        
        CGContextAddPath(ctx, bookmarkPath);
        CGContextStrokePath(ctx);
        
        CGPathRelease(docPath);
        CGPathRelease(bookmarkPath);
    }];
}

+ (UIImage *)styleTableDisclosureImage
{
    static UIImage *_styleDisclosureImage = nil;
    if (!_styleDisclosureImage)
    {
        _styleDisclosureImage = [UIImage imageWithSize:(CGSize){ 9, 14 } block:^(CGContextRef ctx, CGRect rect) {
            // Account for shadow
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
            // Draw shadow
            CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundShadowColor].CGColor);
            CGContextSaveGState(ctx);
            {
                CGContextTranslateCTM(ctx, 0, 1);
                CGContextAddPath(ctx, path);
                CGContextStrokePath(ctx);
            }
            CGContextRestoreGState(ctx);
            // Draw body
            CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
            CGContextAddPath(ctx, path);
            CGContextStrokePath(ctx);
            //
            CGPathRelease(path);
        }];
    }
    return _styleDisclosureImage;
}

+ (UIImage *)styleDisclosureArrowImageWithOrientation:(UIImageOrientation)orientation color:(UIColor *)color
{
    CGSize imageSize = (CGSize){ 14, 9 };
    if (orientation == UIImageOrientationLeft || orientation == UIImageOrientationRight)
        imageSize = (CGSize){ 9, 14 };
    return [UIImage imageWithSize:imageSize block:^(CGContextRef ctx, CGRect rect) {
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
    return [UIImage imageWithSize:(CGSize){ 14, shadowColor ? 15 : 14 } block:^(CGContextRef ctx, CGRect rect) {
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
        {
            CGContextSetStrokeColorWithColor(ctx, shadowColor.CGColor);
            CGContextSaveGState(ctx);
            {
                CGContextTranslateCTM(ctx, 0, 1);
                CGContextAddPath(ctx, path);
                CGContextStrokePath(ctx);
            }
            CGContextRestoreGState(ctx);
        }
        
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextAddPath(ctx, path);
        CGContextStrokePath(ctx);
        
        CGPathRelease(path);
    }];
}

+ (UIImage *)styleCloseImageWithColor:(UIColor *)color outlineColor:(UIColor *)outlineColor
{
    return [UIImage imageWithSize:(CGSize){16, 16} block:^(CGContextRef ctx, CGRect rect) {
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
        
        CGPathRelease(path);
    }];
}

@end

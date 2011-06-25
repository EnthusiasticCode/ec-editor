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

+ (UIImage *)styleDisclosureImage
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

+ (UIImage *)styleAddImage
{
    static UIImage *_styleAddImage = nil;
    if (!_styleAddImage)
    {
        _styleAddImage = [UIImage imageWithSize:(CGSize){ 14, 15 } block:^(CGContextRef ctx, CGRect rect) {
            // Accounting for shadow
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
            
            CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundShadowColor].CGColor);
            CGContextSaveGState(ctx);
            {
                CGContextTranslateCTM(ctx, 0, 1);
                CGContextAddPath(ctx, path);
                CGContextStrokePath(ctx);
            }
            CGContextRestoreGState(ctx);
            
            CGContextSetStrokeColorWithColor(ctx, [UIColor styleForegroundColor].CGColor);
            CGContextAddPath(ctx, path);
            CGContextStrokePath(ctx);
            
            CGPathRelease(path);
        }];
    }
    return _styleAddImage;
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

//
//  MokupControlsViewController.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MokupControlsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+BlockDrawing.h"
#import "UIColor+StyleColors.h"

@implementation MokupControlsViewController
@synthesize jumpBar;
@synthesize popoverContentViewController;
@synthesize imageView;
@synthesize imageView2;
@synthesize projectImageView;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor styleBackgroundColor];
    
    jumpBar.delegate = self;
    jumpBar.backgroundColor = [UIColor styleAlternateBackgroundColor];
    jumpBar.textColor = [UIColor styleForegroundColor];
    jumpBar.textShadowColor = [UIColor styleForegroundShadowColor];
    jumpBar.buttonColor = [UIColor styleBackgroundColor];
    
    popoverContentViewController.view.backgroundColor = [UIColor styleBackgroundColor];
    popoverContentViewController.view.layer.cornerRadius = 3;
    popoverContentViewController.contentSizeForViewInPopover = CGSizeMake(200, 300);
    popoverController = [[ECPopoverController alloc] initWithContentViewController:popoverContentViewController];
    NSMutableArray *passthrough = [NSMutableArray array];
    for (UIControl *control in self.view.subviews) 
    {
        if ([control isKindOfClass:[UIButton class]]) 
            [passthrough addObject:control];
    }
    popoverController.passthroughViews = passthrough;
    [passthrough release];
    
    // Document icon
    imageView.image = [UIImage imageWithSize:imageView.bounds.size block:^(CGContextRef ctx, CGRect rect) {
        CGFloat margin = ceilf(rect.size.width / 20);
        rect.origin.x += margin;
        rect.size.width -= margin * 2;
        
        CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
        
        CGFloat line = ceilf(rect.size.height / 7.0);
        CGFloat corner = ceilf(rect.size.height / 4.0);
        CGRect innerRect = CGRectInset(rect, line, line);
        
        // Top line
        CGContextFillRect(ctx, (CGRect){ 
            rect.origin, 
            { rect.size.width - corner, line } 
        });
        // Left line
        CGContextFillRect(ctx, (CGRect){ 
            { rect.origin.x, innerRect.origin. y }, 
            { line, rect.size.height } 
        });
        // Right line
        CGContextFillRect(ctx, (CGRect){ 
            { innerRect.origin.x + innerRect.size.width, rect.origin.y + corner }, 
            { line, rect.size.height - corner } 
        });
        // Bottom line
        CGContextFillRect(ctx, (CGRect){ 
            { innerRect.origin.x, innerRect.origin.y + innerRect.size.height }, 
            { innerRect.size.width, line } 
        });
        
        
        // Corner
        CGFloat innerCorner = ceilf(corner * 1.3);
        CGContextMoveToPoint(ctx, rect.origin.x + rect.size.width - corner, rect.origin.y);
        CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width, rect.origin.y + corner);
        CGContextAddLineToPoint(ctx, innerRect.origin.x + innerRect.size.width, rect.origin.y + innerCorner);
        CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width - innerCorner, rect.origin.y + line);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
    }];
    
    imageView2.image = [UIImage imageWithSize:imageView2.bounds.size block:^(CGContextRef ctx, CGRect rect) {
        CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
        
        CGFloat line = ceilf(rect.size.height / 7.0);
        CGFloat mid = ceilf(rect.size.height / 2.0);
        CGFloat midInner = ceilf(rect.size.height / 43);
        CGFloat midOutter = ceilf(rect.size.height / 32);
        CGFloat innerLeft = mid - midInner;
        CGFloat outterLeft = innerLeft - midOutter;
        CGFloat innerRight = mid + midInner;
        CGFloat outterRight = innerRight + midOutter;
        CGFloat topInset = ceilf(rect.size.height / 8.0);
        
        CGRect innerRect = CGRectInset(rect, line, line);
        
        // Top line
        CGContextFillRect(ctx, (CGRect) {
            rect.origin,
            { innerLeft, line }
        });
        CGContextFillRect(ctx, (CGRect) {
            { rect.origin.x + innerRight, rect.origin.y + topInset },
            { rect.size.width - innerRight, line }
        });
        // Right line
        CGContextFillRect(ctx, (CGRect) {
            { innerRect.origin.x + innerRect.size.width, rect.origin.y + topInset + line },
            { line, innerRect.size.height }
        });
        // Left line
        CGContextFillRect(ctx, (CGRect) {
            { rect.origin.x, innerRect.origin.y },
            { line, innerRect.size.height }
        });
        // Bottom line
        CGContextFillRect(ctx, (CGRect) {
            { rect.origin.x, innerRect.origin.y + innerRect.size.height },
            { rect.size.width, line }
        });
        
        // Corner (assuming origin at 0,0)
        CGContextMoveToPoint(ctx, innerLeft, 0);
        CGContextAddLineToPoint(ctx, outterRight, topInset);
        CGContextAddLineToPoint(ctx, innerRight, topInset + line);
        CGContextAddLineToPoint(ctx, outterLeft, line);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
    }];
    
    projectImageView.image = [UIImage imageWithSize:projectImageView.bounds.size block:^(CGContextRef ctx, CGRect rect) {
        CGRect orect = rect;
        CGFloat marginLeft = ceilf(rect.size.width / 10);
        rect.origin.x += marginLeft;
        rect.size.width -= marginLeft;
        
        //
        CGFloat mid = orect.origin.x + ceilf(orect.size.width / 2);
        CGFloat bspaceInner = orect.origin.y + ceilf(orect.size.height * 0.61);
        CGFloat bspaceOutter = orect.origin.y + ceilf(orect.size.height * 0.69);
        
        // Draw document
        CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
        
        CGFloat line = ceilf(rect.size.height / 7.0);
        CGFloat corner = ceilf(rect.size.height / 4.0);
        CGRect innerRect = CGRectInset(rect, line, line);
        
        // Top line
        CGContextFillRect(ctx, (CGRect){ 
            { mid, rect.origin.y } , 
            { mid - corner, line } 
        });
        // Left line
        CGContextFillRect(ctx, (CGRect){ 
            { rect.origin.x, bspaceOutter }, 
            { line, rect.size.height } 
        });
        CGContextMoveToPoint(ctx, rect.origin.x, bspaceOutter);
        CGContextAddLineToPoint(ctx, rect.origin.x + line, bspaceInner);
        CGContextAddLineToPoint(ctx, rect.origin.x + line, bspaceOutter);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
        // Right line
        CGContextFillRect(ctx, (CGRect){ 
            { innerRect.origin.x + innerRect.size.width, rect.origin.y + corner }, 
            { line, rect.size.height - corner } 
        });
        // Bottom line
        CGContextFillRect(ctx, (CGRect){ 
            { innerRect.origin.x, innerRect.origin.y + innerRect.size.height }, 
            { innerRect.size.width, line } 
        });
        
        
        // Corner
        CGFloat innerCorner = ceilf(corner * 1.3);
        CGContextMoveToPoint(ctx, rect.origin.x + rect.size.width - corner, rect.origin.y);
        CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width, rect.origin.y + corner);
        CGContextAddLineToPoint(ctx, innerRect.origin.x + innerRect.size.width, rect.origin.y + innerCorner);
        CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width - innerCorner, rect.origin.y + line);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
        
        // Draw bookmark
        CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:64.0/255.0 green:92.0/255.0 blue:123.0/255.0 alpha:1].CGColor);
        CGContextSetLineWidth(ctx, 1);

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
        
        CGContextAddPath(ctx, bookmarkPath);
        CGContextFillPath(ctx);
        
        CGContextAddPath(ctx, bookmarkPath);
        CGContextStrokePath(ctx);
        
        CGPathRelease(bookmarkPath);
    }];
}

- (void)viewDidUnload
{
    [popoverController release];
    
    [self setJumpBar:nil];
    [self setImageView:nil];
    [self setImageView2:nil];
    [self setProjectImageView:nil];
    [self setPopoverContentViewController:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (IBAction)pushToJumpBar:(id)sender {
    [jumpBar pushControlWithTitle:[NSString stringWithFormat:@"%dProject", jumpBar.stackSize] animated:YES];
}

#pragma mark Jump Bar Delegation

- (IBAction)showPopover:(id)sender {
    NSUInteger tag = [sender tag];
//    [popoverController setPopoverContentSize:(CGSize){ 270, 300 }];
    [popoverController presentPopoverFromRect:[sender frame] inView:self.view permittedArrowDirections:tag ? tag :UIPopoverArrowDirectionAny animated:YES];
}

- (void)jumpBarButtonAction:(id)sender
{
    [jumpBar popControlsDownThruIndex:[sender tag] animated:YES];
}

- (void)jumpBar:(ECJumpBar *)jumpBar didPushControl:(UIControl *)control atStackIndex:(NSUInteger)index
{
    [control addTarget:self action:@selector(jumpBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)jumpBar:(ECJumpBar *)jumpBar didCollapseToControl:(UIControl *)control collapsedRange:(NSRange)collapsedRange
{

}
- (void)dealloc {
    [popoverContentViewController release];
    [super dealloc];
}
@end

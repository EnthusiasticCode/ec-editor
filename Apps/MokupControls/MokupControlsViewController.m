//
//  MokupControlsViewController.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MokupControlsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ECMockupLayer.h"
#import "UIImage+BlockDrawing.h"

@implementation MokupControlsViewController
@synthesize aButton;
@synthesize jumpBar;
@synthesize imageView;
@synthesize imageView2;

- (void)dealloc
{
    [aButton release];
    [jumpBar release];
    [imageView release];
    [imageView2 release];
    [super dealloc];
}

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

    aButton.arrowSizes = UIEdgeInsetsMake(0, 10, 0, 0);
    
    jumpBar.delegate = self;
    
    // Document icon
    imageView.image = [UIImage imageWithSize:imageView.bounds.size block:^(CGContextRef ctx, CGRect rect) {
        [[UIColor blackColor] setFill];
        
        CGFloat margin = ceilf(rect.size.width / 20);
        rect.origin.x += margin;
        rect.size.width -= margin * 2;
        
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
        [[UIColor blackColor] setFill];
        
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
}

- (void)viewDidUnload
{
    [self setAButton:nil];
    [self setJumpBar:nil];
    [self setImageView:nil];
    [self setImageView2:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (IBAction)pushToJumpBar:(id)sender {
    [jumpBar pushControlWithTitle:[NSString stringWithFormat:@"%dProject", jumpBar.stackSize]];
}

#pragma mark Jump Bar Delegation

- (void)jumpBarButtonAction:(id)sender
{
    [jumpBar popControlsDownThruIndex:[sender tag]];
}

- (void)jumpBar:(ECJumpBar *)jumpBar didPushControl:(UIControl *)control atStackIndex:(NSUInteger)index
{
    [control addTarget:self action:@selector(jumpBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)jumpBar:(ECJumpBar *)jumpBar didCollapseToControl:(UIControl *)control collapsedRange:(NSRange)collapsedRange
{

}
@end

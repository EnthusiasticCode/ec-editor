//
//  ItemViewViewController.m
//  ItemView
//
//  Created by Uri Baghin on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ItemViewViewController.h"

@implementation ItemViewViewController
@synthesize itemViewA;
@synthesize itemViewB;

- (void)dealloc
{
    [itemViewA release];
    [itemViewB release];
    [super dealloc];
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableArray *itemsA = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
    for (NSUInteger i = 0; i < 5; ++i)
        [itemsA addObject:[self randomColorCell]];
    NSMutableArray *itemsB = [[[NSMutableArray alloc] initWithCapacity:9] autorelease];
    for (NSUInteger i = 0; i < 9; ++i)
        [itemsB addObject:[self randomColorCell]];
    self.itemViewA.items = itemsA;
    self.itemViewB.items = itemsB;
}

- (void)viewDidUnload
{
    [self setItemViewA:nil];
    [self setItemViewB:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (UIView *)randomColorCell
{
    UIView *cell = [[[UIView alloc] init] autorelease];
    cell.backgroundColor = [UIColor colorWithRed:1.0/(rand() % 5 + 1) green:1.0/(rand() % 5 + 1) blue:1.0/(rand() % 5 + 1) alpha:1.0];
    cell.clipsToBounds = YES;
    return cell;
}

- (IBAction)batchUpdates:(id)sender
{
    [self.itemViewA beginUpdates];
    [self.itemViewA insertItem:[self randomColorCell] atIndex:1];
    [self.itemViewA insertItem:[self randomColorCell] atIndex:2];
    [self.itemViewA removeItemAtIndex:4];
    [self.itemViewA removeItemAtIndex:5];
    [self.itemViewA replaceItemAtIndex:3 withItem:[self randomColorCell]];
    [self.itemViewA endUpdates];
}

- (void)itemView:(ECItemView *)itemView didSelectItem:(NSUInteger)item
{
    [itemView replaceItemAtIndex:item withItem:[self randomColorCell]];
}

- (BOOL)itemView:(ECItemView *)itemView shouldDragItem:(NSUInteger)item inView:(UIView **)view
{
    UIView *rootView = self.view;
    *view = rootView;
    return YES;
}

- (BOOL)itemView:(ECItemView *)itemView canDropItem:(NSUInteger)item inTargetItemView:(ECItemView *)targetItemView
{
    return YES;
}

@end

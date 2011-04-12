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

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [self setItemViewA:nil];
    [self setItemViewB:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (NSInteger)numberOfItemsInItemView:(ECItemView *)itemView
{
    if (itemView == itemViewA)
        return 5;
    if (itemView == itemViewB)
        return 9;
    return 0;
}

- (ECItemViewCell *)itemView:(ECItemView *)itemView cellForItem:(NSInteger)item
{
    ECItemViewCell *cell = [[[ECItemViewCell alloc] init] autorelease];
//    cell.backgroundColor = [UIColor redColor];
    cell.backgroundColor = [UIColor colorWithRed:1.0/(rand() % 5 + 1) green:1.0/(rand() % 5 + 1) blue:1.0/(rand() % 5 + 1) alpha:1.0];
    return cell;
}

- (IBAction)batchUpdates:(id)sender {
    [self.itemViewA beginUpdates];
    [self.itemViewA insertItems:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]];
    [self.itemViewA deleteItems:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 2)]];
    [self.itemViewA reloadItems:[NSIndexSet indexSetWithIndex:4]];
    [self.itemViewA endUpdates];
}

- (void)itemView:(ECItemView *)itemView didSelectItem:(NSInteger)item
{
    [itemView beginUpdates];
    [itemView reloadItems:[NSIndexSet indexSetWithIndex:item]];
    [itemView endUpdates];
}

- (BOOL)itemView:(ECItemView *)itemView shouldDragItem:(NSInteger)item inView:(UIView **)view
{
    UIView *rootView = self.view;
    *view = rootView;
    return YES;
}

- (BOOL)itemView:(ECItemView *)itemView canDropItem:(NSInteger)item inTargetItemView:(ECItemView *)targetItemView
{
    return YES;
}

@end

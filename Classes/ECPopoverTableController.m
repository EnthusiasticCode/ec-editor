//
//  ECPopoverTableController.m
//  edit
//
//  Created by Uri Baghin on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPopoverTableController.h"

#import <UIKit/UILabel.h>


@implementation ECPopoverTableController


@synthesize strings = _strings;
@synthesize delegate;
@synthesize popoverRect;
@synthesize viewToPresentIn;

- (void)setStrings:(NSArray *)strings
{
    if (![strings count])
    {
        [_popover dismissPopoverAnimated:YES];
    }
    else
    {
        _strings = [strings retain];
        [self.tableView reloadData];
        [_popover presentPopoverFromRect:self.popoverRect inView:self.viewToPresentIn permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        _popover = [[UIPopoverController alloc] initWithContentViewController:self];
        _popover.delegate = (id)self;
        _popover.popoverContentSize = CGSizeMake(150.0, 400.0);
    }
    return self;
}

- (void)dealloc {
    self.strings = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.strings)
        return [self.strings count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *completion = [tableView dequeueReusableCellWithIdentifier:@"Completion"];
    if (!completion)
    {
        completion = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Completion"] autorelease];
    }
    completion.textLabel.text = [self.strings objectAtIndex:(indexPath.row)];
    return completion;
}

#pragma mark -
#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(popoverTableDidSelectRowWithText:)])
        [self.delegate popoverTableDidSelectRowWithText:[self.strings objectAtIndex:indexPath.row]];
}

@end

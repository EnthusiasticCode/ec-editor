//
//  ACToolController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 10/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolController.h"
#import <QuartzCore/QuartzCore.h>

@implementation ACToolController

@synthesize tabButton;
@synthesize tableView, filterContainerView, filterTextField, filterAddButton;

#pragma mark - Private Methods

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    CGRect toFrame = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    UIViewAnimationCurve animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect filterContainerFrame = filterContainerView.frame;
    if(fabsf(toFrame.size.height) < 264.)
    {
        filterContainerFrame.origin.y = self.view.bounds.size.height - filterContainerFrame.size.height;
    }
    else
    {
        filterContainerFrame.origin.y = toFrame.origin.y - filterContainerFrame.size.height;
    }
    
    CGRect tableViewFrame = tableView.frame;
    tableViewFrame.size.height = filterContainerFrame.origin.y - tableViewFrame.origin.y;
    
    [UIView animateWithDuration:animationDuration delay:0 options:animationCurve << 16 animations:^(void) {
        filterContainerView.frame = filterContainerFrame;
        tableView.frame = tableViewFrame;
    } completion:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    // Table View
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [UIColor styleBackgroundColor];
    // TODO Write hints in this view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 10)];
    tableView.tableFooterView = footerView;
    
    // Filters container
    if (filterContainerView)
    {
        CALayer *layer = filterContainerView.layer;
        layer.borderColor = [UIColor styleBackgroundColor].CGColor;
        layer.borderWidth = 1;
    }
    
    // Filter text field
    if (filterTextField)
    {
        filterTextField.rightView = [[UIImageView alloc] initWithImage:[UIImage styleSearchIconWithColor:[UIColor styleBackgroundColor] shadowColor:nil]];
        filterTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    }
    
    // Add button
    if (filterAddButton)
    {
        [filterAddButton setImage:[UIImage styleAddImageWithColor:[UIColor styleBackgroundColor] shadowColor:nil] forState:UIControlStateNormal];
        CALayer *layer = filterAddButton.layer;
        layer.borderColor = [UIColor styleBackgroundColor].CGColor;
        layer.borderWidth = 1;
    }
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setTableView:nil];
    [self setFilterContainerView:nil];
    [self setFilterTextField:nil];
    [self setFilterAddButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        static UIImage *disclosureImage = nil;
        if (!disclosureImage)
            disclosureImage = [UIImage styleTableDisclosureImageWithColor:[UIColor styleBackgroundColor] shadowColor:nil];
        cell.accessoryView = [[UIImageView alloc] initWithImage:disclosureImage];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.textLabel.textColor = [UIColor styleBackgroundColor];
        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [UIColor styleHighlightColor];
    }
    
    return cell;
}

@end

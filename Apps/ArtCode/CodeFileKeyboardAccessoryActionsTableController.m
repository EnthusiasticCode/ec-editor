//
//  CodeFileKeyboardAccessoryActionsTableController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CodeFileKeyboardAccessoryActionsTableController.h"
#import "CodeFileAccessoryAction.h"


@interface AccessoryActionTableCell : UITableViewCell

@property (nonatomic, strong, readonly) UIButton *buttonPreview;

@end


@implementation CodeFileKeyboardAccessoryActionsTableController {
    NSArray *_actions;
}

@synthesize languageIdentifier, didSelectActionItemBlock, buttonBackgroundImage;

- (void)setLanguageIdentifier:(NSString *)value
{
    if (value == languageIdentifier)
        return;
    [self willChangeValueForKey:@"languageIdentifier"];
    languageIdentifier = value;
    _actions = nil;
    if (self.isViewLoaded)
        [self.tableView reloadData];
    [self didChangeValueForKey:@"languageIdentifier"];
}

- (NSArray *)actions
{
    if (!_actions && self.languageIdentifier)
    {
        _actions = [CodeFileAccessoryAction accessoryActionsForLanguageWithIdentifier:self.languageIdentifier];
    }
    return _actions;
}

#pragma mark - View lifecycle

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _actions = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self actions] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    AccessoryActionTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AccessoryActionTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell.buttonPreview setBackgroundImage:self.buttonBackgroundImage forState:UIControlStateNormal];
        [cell.buttonPreview setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        cell.buttonPreview.titleLabel.font = [UIFont systemFontOfSize:21];
    }
    
    CodeFileAccessoryAction *action = [[self actions] objectAtIndex:indexPath.row];
    cell.textLabel.text = [action.description length] ? action.description : action.title;
    
    UIImage *actionImage = [UIImage imageNamed:action.imageName];
    if (actionImage)
    {
        [cell.buttonPreview setImage:actionImage forState:UIControlStateNormal];
        [cell.buttonPreview setTitle:nil forState:UIControlStateNormal];
    }
    else
    {
        [cell.buttonPreview setImage:nil forState:UIControlStateNormal];
        [cell.buttonPreview setTitle:action.title forState:UIControlStateNormal];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.didSelectActionItemBlock)
        self.didSelectActionItemBlock(self, [[self actions] objectAtIndex:indexPath.row]);
}

@end


@implementation AccessoryActionTableCell

@synthesize buttonPreview;

- (UIButton *)buttonPreview
{
    if (!buttonPreview)
    {
        buttonPreview = [UIButton new];
        buttonPreview.userInteractionEnabled = NO;
        [self.contentView addSubview:buttonPreview];
    }
    return buttonPreview;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (buttonPreview)
    {
        CGRect bounds = self.contentView.bounds;
        buttonPreview.frame = CGRectMake(2, 2, 60, bounds.size.height - 2);
        self.textLabel.frame = CGRectMake(66, 0, bounds.size.width - 66, bounds.size.height);
    }
}

@end

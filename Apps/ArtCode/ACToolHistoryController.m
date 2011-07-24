//
//  ACToolHistoryController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 10/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolHistoryController.h"

@implementation ACToolHistoryController {
    UIImage *redoImage;
    UIImage *nowImage;
    UIImage *undoImage;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    redoImage = [UIImage imageNamed:@"toolHistoryForward.png"];
    nowImage = [UIImage imageNamed:@"toolHistoryNow.png"];
    undoImage = [UIImage imageNamed:@"toolHistoryBack.png"];
}

- (void)viewDidUnload
{
    redoImage = nil;
    nowImage = nil;
    undoImage = nil;
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:table cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    NSUInteger idx = [indexPath indexAtPosition:1];
    switch (idx) {
        case 0:
            cell.imageView.image = redoImage;
            break;
            
        case 1:
            cell.imageView.image = nowImage;
            break;
            
        default:
            cell.imageView.image = undoImage;
            break;
    }
    
    cell.textLabel.text = @"prova";
    cell.detailTextLabel.text = @"subtext";
    
    return cell;
}

@end

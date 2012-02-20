//
//  RemoteBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteBrowserController.h"
#import "HighlightTableViewCell.h"

@interface RemoteBrowserController ()

@end

@implementation RemoteBrowserController

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath]; 
    return cell;
}

@end

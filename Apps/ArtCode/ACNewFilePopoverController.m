//
//  ACNewFilePopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNewFilePopoverController.h"

@implementation ACNewFilePopoverController

@synthesize group = _group;
@synthesize folderButton = _folderButton;
@synthesize groupButton = _groupButton;
@synthesize fileButton = _fileButton;
@synthesize fileImportTableView = _fileImportTableView;

- (void)viewDidLoad
{
    self.fileImportTableView.dataSource = self;
    self.fileImportTableView.delegate = self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellReuseIdentifier = @"FileImportTableCell";
    UITableViewCell *cell = [self.fileImportTableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
    }
    
    return cell;
}

@end

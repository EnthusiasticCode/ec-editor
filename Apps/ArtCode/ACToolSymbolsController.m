//
//  ACToolSymbolsController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 10/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolSymbolsController.h"

@implementation ACToolSymbolsController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor colorWithWhite:0.3 alpha:1];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 9;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath indexAtPosition:1] % 3 ? 40 : 30;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *symbolCellIdentifier = @"SymbolCell";
    static NSString *pragmaCellIdentifier = @"PragmaCell";
    
    NSUInteger idx = [indexPath indexAtPosition:1];
    BOOL isPragma = idx % 3 == 0;
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:isPragma ? pragmaCellIdentifier : symbolCellIdentifier];
    if (cell == nil)
    {
        if (isPragma)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:pragmaCellIdentifier];
            cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
            cell.textLabel.font = [UIFont styleFontWithSize:14];
            cell.indentationWidth = 25;
        }
        else
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:symbolCellIdentifier];
            cell.textLabel.textColor = [UIColor styleBackgroundColor];   
        }        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [UIColor styleHighlightColor];
    }
    
    cell.textLabel.text = isPragma ? @"pragma" : @"symbol";
    
    if (!isPragma)
        cell.imageView.image = [UIImage styleSymbolImageWithColor:[UIColor styleThemeColorOne] letter:@"M"];
    else if (idx > 0)
        cell.indentationLevel = 1;
    
    return cell;
}

@end

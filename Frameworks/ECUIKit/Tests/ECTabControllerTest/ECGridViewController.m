//
//  ECGridViewController.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ECGridViewController.h"


@implementation ECGridViewController

- (void)loadView
{
    ECGridView *gridView = [[ECGridView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    gridView.delegate = self;
    gridView.dataSource = self;
    
    gridView.backgroundColor = [UIColor grayColor];
    gridView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    
    self.view = gridView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark Grid View Data Source

- (NSInteger)numberOfCellsForGridView:(ECGridView *)gridView
{
    return 30;
}

- (ECGridViewCell *)gridView:(ECGridView *)gridView cellAtIndex:(NSInteger)cellIndex
{
    static NSString *cellIdengifier = @"cell";
    
    TestCell *cell = [gridView dequeueReusableCellWithIdentifier:cellIdengifier];
    if (!cell)
    {
        cell = [[TestCell alloc] initWithFrame:CGRectMake(0, 0, 20, 20) reuseIdentifier:cellIdengifier];
        cell.backgroundView = [UIView new];
        cell.backgroundView.backgroundColor = [UIColor darkGrayColor];
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [UIColor redColor];
        cell.contentInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    
    cell.label.text = [NSString stringWithFormat:@"%d", cellIndex];
    
    return cell;
}

@end


@implementation TestCell

@synthesize label;

- (UILabel *)label
{
    if (!label)
    {
        label = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:label];
    }
    return label;
}

@end
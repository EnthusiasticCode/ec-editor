//
//  ACCodeFileFilterController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECCodeView;
@class ACCodeFileFilterController;


typedef void (^ACCodeFileFilterBlock)(ACCodeFileFilterController *sender);

/// A controller that present a filtrable list of code view related elements.
/// Without filtering, the controller displays a list of symbols derived from 
/// the target code indexer datasource's code unit.
/// When filtering the following elements are displayed under categories in order:
/// - Filtered symbols (if any present)
/// - Searches in file's content (if any present)
/// - go to line, column (if filter string is a proper number pair)
@interface ACCodeFileFilterController : UIViewController <UITableViewDelegate, UITableViewDataSource>

#pragma mark Managing Filtering

/// Code view to which apply the filter.
@property (weak, nonatomic) ECCodeView *targetCodeView;

/// Specify the string to use to filter the content.
@property (strong, nonatomic) NSString *filterString;

#pragma mark Customizing Controller Actions

@property (copy, nonatomic) ACCodeFileFilterBlock startSearchingBlock;
@property (copy, nonatomic) ACCodeFileFilterBlock endSearchingBlock;

#pragma mark Controlled Views

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *replaceToolView;

@end

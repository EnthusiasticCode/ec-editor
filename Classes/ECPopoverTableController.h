//
//  ECPopoverTableController.h
//  edit
//
//  Created by Uri Baghin on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*! A UIViewController subclass which manages a UITableView presented with a UIPopoverController.
 *
 * To use it, assign the popoverRect and viewToPresentIn properties, then:
 * - assign a non-empty NSArray to the strings property to present the UITableView with the contents of the array as options
 * - assign nil or an empty NSArray to the strings property to hide the UITableView
 */
@interface ECPopoverTableController : UITableViewController{
    @private
    UIPopoverController *_popover;
}
/*! An NSArray representing the choices the controller will display. */
@property (nonatomic,retain) NSArray *strings;
/*! The rect in which to present the popover. */
@property (nonatomic) CGRect popoverRect;
/*! The view in which to present the popover. Must have a valid window. */
@property (nonatomic,assign) UIView *viewToPresentIn;
/*! An block to be executed when the user selects a row in the table. */
@property (nonatomic, copy) void(^didSelectRow)(int row);

@end

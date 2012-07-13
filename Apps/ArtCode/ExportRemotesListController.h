//
//  ExportRemotesListController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArtCodeRemote;

/// A controller that can be used to display a list of remotes.
/// The controller is supposed to be used inside a modal navigation controller.
/// For convinience, it defines a block callback called when a remote is selected.
@interface ExportRemotesListController : UITableViewController

/// The list of remotes to show on this controller.
@property (nonatomic, strong) NSArray *remotes;

/// A block that will be called when the user select a remote from the list.
@property (nonatomic, copy) void (^remoteSelectedBlock)(ExportRemotesListController *sender, ArtCodeRemote *remote);

@end

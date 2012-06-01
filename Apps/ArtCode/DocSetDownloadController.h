//
//  DocSetDownloadController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocSetDownloadController : UITableViewController

@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *infoProgress;

- (IBAction)refreshDocSetList:(id)sender;
@end

//
//  DocSetOutlineController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class DocSet;

@interface DocSetOutlineController : UITableViewController <UISearchDisplayDelegate>

- (id)initWithDocSet:(DocSet *)set rootNode:(NSManagedObject *)rootNode;

@end

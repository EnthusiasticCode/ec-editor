//
//  ProjectsTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class Application, ArtCodeTab, ProjectCell;


@interface ProjectBrowserController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) NSOrderedSet *projectsSet;

/// An hint view that will be displayed if there are no projects
@property (nonatomic, strong) IBOutlet UIView *hintView;

@end

@interface ProjectCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *newlyCreatedBadge;

@property (nonatomic) BOOL jiggle;

@end

@interface ProjectCollectionLayout : UICollectionViewLayout

@property (nonatomic) UIEdgeInsets sectionInset;
@property (nonatomic) CGFloat itemHeight;
@property (nonatomic) CGFloat interItemSpacing;
@property (nonatomic) NSUInteger numberOfColumns;

@end
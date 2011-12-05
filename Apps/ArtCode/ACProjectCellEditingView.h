//
//  ACProjectCellEditingView.h
//  ArtCode
//
//  Created by Uri Baghin on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACProjectCellEditingView : UIView

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet UIButton *configureButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;

@end

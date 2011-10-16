//
//  ACFileDocument.h
//  ArtCode
//
//  Created by Uri Baghin on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECCodeView.h>

@class ECCodeUnit, TMTheme;

@interface ACFileDocument : UIDocument <ECCodeViewDataSource>

@property (nonatomic, strong) TMTheme *theme;

@end

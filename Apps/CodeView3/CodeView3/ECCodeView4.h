//
//  ECCodeView4.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextRendererDatasource.h"


@interface ECCodeView4 : UIScrollView <ECTextRendererDatasource>

@property (nonatomic, retain) NSAttributedString *text;

@property (nonatomic) UIEdgeInsets textInsets;

@end

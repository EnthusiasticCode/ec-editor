//
//  ECCodeStringDataSource.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 23/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeViewDatasource.h"
#import "ECTextStyle.h"

@interface ECCodeStringDataSource : NSObject <ECCodeViewDataSource>

@property (nonatomic, retain) NSString *string;

@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

@end

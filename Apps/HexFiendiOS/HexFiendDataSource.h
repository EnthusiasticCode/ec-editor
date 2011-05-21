//
//  HexFiendDataSource.h
//  HexFiendiOS
//
//  Created by Uri Baghin on 5/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeViewDatasource.h"

@interface HexFiendDataSource : NSObject <ECCodeViewDataSource>
@property (nonatomic, retain) NSString *file;
@end

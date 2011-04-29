//
//  NameWord.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"

@interface NameWord : ECManagedObject
@property (nonatomic, retain) NSString * normalizedWord;
@property (nonatomic, retain) NSSet* nodes;
@end

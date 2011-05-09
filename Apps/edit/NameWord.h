//
//  NameWord.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ECManagedObject.h"

@class Node;

@interface NameWord : ECManagedObject {
@private
}
@property (nonatomic, retain) NSString * normalizedWord;
@property (nonatomic, retain) NSSet* nodes;

@end

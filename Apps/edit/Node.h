//
//  Node.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ECManagedObject.h"

@class NameWord, Node;

@interface Node : ECManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * collapsed;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet* nameWords;
@property (nonatomic, retain) Node * parent;
@property (nonatomic, retain) NSSet* children;

@end

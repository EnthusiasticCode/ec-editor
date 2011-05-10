//
//  CDNode.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ECManagedObject.h"

@class CDNameWord, CDNode;

@interface CDNode : ECManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * collapsed;
@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) CDNode * parent;
@property (nonatomic, retain) NSSet* children;
@property (nonatomic, retain) NSSet* nameWords;

@end

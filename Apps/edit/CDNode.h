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
@property (nonatomic, strong) NSNumber * collapsed;
@property (nonatomic, strong) NSNumber * tag;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * index;
@property (nonatomic, strong) CDNode * parent;
@property (nonatomic, strong) NSSet* children;
@property (nonatomic, strong) NSSet* nameWords;

@end

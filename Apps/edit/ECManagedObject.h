//
//  ECManagedObject.h
//  edit
//
//  Created by Uri Baghin on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ECManagedObject : NSManagedObject
- (NSArray *)valueForOrderedKey:(NSString *)key;
- (NSArray *)copyForOrderedKey:(NSString *)key;
- (NSMutableArray *)mutableArrayValueForOrderedKey:(NSString *)key;
- (NSMutableArray *)mutableCopyForOrderedKey:(NSString *)key;
- (NSUInteger)countForOrderedKey:(NSString *)key;
- (id)objectAtIndex:(NSUInteger)index forOrderedKey:(NSString *)key;
- (void)addObject:(id)anObject forOrderedKey:(NSString *)key;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index forOrderedKey:(NSString *)key;
- (void)removeLastObjectForOrderedKey:(NSString *)key;
- (void)removeObjectAtIndex:(NSUInteger)index forOrderedKey:(NSString *)key;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject forOrderedKey:(NSString *)key;
@end

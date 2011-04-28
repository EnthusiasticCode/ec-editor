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
- (NSMutableArray *)mutableArrayValueForOrderedKey:(NSString *)key;
- (NSArray *)copyForOrderedKey:(NSString *)key;
- (NSMutableArray *)mutableCopyForOrderedKey:(NSString *)key;
- (NSUInteger)countForOrderedKey:(NSString *)key;
- (id)objectAtIndex:(NSUInteger)index forOrderedKey:(NSString *)key;
- (void)addObject:(id)object forOrderedKey:(NSString *)key;
- (void)removeObject:(id)object forOrderedKey:(NSString *)key;
- (void)insertObject:(id)object atIndex:(NSUInteger)index forOrderedKey:(NSString *)key;
- (void)removeLastObjectForOrderedKey:(NSString *)key;
- (void)removeObjectAtIndex:(NSUInteger)index forOrderedKey:(NSString *)key;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object forOrderedKey:(NSString *)key;
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2 forOrderedKey:(NSString *)key;
- (void)moveObjectAtIndex:(NSUInteger)idx1 toIndex:(NSUInteger)idx2 forOrderedKey:(NSString *)key;
- (void)addObjects:(NSSet *)objects forOrderedKey:(NSString *)key;
- (void)removeObjects:(NSSet *)objects forOrderedKey:(NSString *)key;
- (NSArray *)subarrayWithRange:(NSRange)range forOrderedKey:(NSString *)key;
@end

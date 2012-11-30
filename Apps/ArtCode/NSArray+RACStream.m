//
//  NSArray+RACStream.m
//  ArtCode
//
//  Created by Uri Baghin on 11/20/12.
//
//

#import "NSArray+RACStream.h"
#import <ReactiveCocoa/RACBlockTrampoline.h>

@implementation NSArray (RACStream)

+ (instancetype)empty {
  return @[];
}

+ (instancetype)return:(id)value {
  return @[ value ];
}

- (instancetype)bind:(RACStreamBindBlock (^)(void))block {
  NSMutableArray *mapped = NSMutableArray.array;
  BOOL stop = NO;
  RACStreamBindBlock bindBlock = block();
  
  for (id value in self) {
    NSArray *result = bindBlock(value, &stop);
    if (!result) {
      break;
    }
    
		NSAssert([result isKindOfClass:NSArray.class], @"-bind: block returned an object that is not an array: %@", result);
    
    [mapped addObject:result];
    if (stop) {
      break;
    }
  }
  
  NSMutableArray *flattened = [NSMutableArray array];
  for (NSArray *value in mapped) {
    [flattened addObjectsFromArray:value];
  }
  return flattened.copy;
}

- (instancetype)concat:(id<RACStream>)stream {
  return [self arrayByAddingObjectsFromArray:(NSArray *)stream];
}

+ (instancetype)zip:(NSArray *)arrays reduce:(id)reduceBlock {
	NSUInteger minCount = NSUIntegerMax;
	for (NSArray *array in arrays) {
		if (minCount > array.count) {
			minCount = array.count;
		}
	}
	NSMutableArray *zippedArray = [NSMutableArray arrayWithCapacity:minCount];
	for (NSUInteger i = 0; i < minCount; ++i) {
		NSMutableArray *nthValues = [NSMutableArray arrayWithCapacity:arrays.count];
		for (NSArray *array in arrays) {
			[nthValues addObject:array[i]];
		}
		if (reduceBlock == NULL) {
			[zippedArray addObject:[RACTuple tupleWithObjectsFromArray:nthValues]];
		} else {
			[zippedArray addObject:[RACBlockTrampoline invokeBlock:reduceBlock withArguments:nthValues]];
		}
	}
	return zippedArray.copy;
}

@end

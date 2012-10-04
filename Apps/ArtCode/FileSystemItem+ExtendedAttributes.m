//
//  FileSystemItem+ExtendedAttributes.m
//  ArtCode
//
//  Created by Uri Baghin on 10/4/12.
//
//

#import "FileSystemItem+ExtendedAttributes.h"
#import "FileSystemItem_Internal.h"
#import "RACEchoSubject.h"

@interface FileSystemItem (ExtendedAttributes_Internal)

// Must be called on fileSystemScheduler
- (RACEchoSubject *)extendedAttributeEchoForKey:(NSString *)key;

// Must be called and delivers on fileSystemScheduler
// The returned subscribable is sent tuples where the first element is the new value, and the second element is the subscribable that sent it originally if applicable
- (id<RACSubscribable>)internalExtendedAttributeForKey:(NSString *)key;

// Must be called and delivers on fileSystemScheduler
- (id<RACSubscribable>)internalBindExtendedAttributeForKey:(NSString *)key to:(id<RACSubscribable>)internalExtendedAttributeSubscribable;

@end

@implementation FileSystemItem (ExtendedAttributes)

- (RACEchoSubject *)extendedAttributeEchoForKey:(NSString *)key {
  ASSERT_NOT_MAIN_QUEUE();
  RACEchoSubject *echo = [self.extendedAttributesEchoes objectForKey:key];
  if (!echo) {
    echo = [RACEchoSubject replaySubjectWithCapacity:1];
    [echo sendNext:[self.extendedAttributesBacking objectForKey:key]];
    [self.extendedAttributesEchoes setObject:echo forKey:key];
    __weak FileSystemItem *weakSelf = self;
    [echo subscribeNext:^(id x) {
      __strong FileSystemItem *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (x) {
        [strongSelf.extendedAttributesBacking setObject:x forKey:key];
      } else {
        [strongSelf.extendedAttributesBacking removeObjectForKey:key];
      }
    }];
  }
  return echo;
}

- (id<RACSubscribable>)internalExtendedAttributeForKey:(NSString *)key {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    return [self extendedAttributeEchoForKey:key];
  }];
}

- (id<RACSubscribable>)internalBindExtendedAttributeForKey:(NSString *)key to:(id<RACSubscribable>)internalExtendedAttributeSubscribable {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    return [[self extendedAttributeEchoForKey:key] echoSubscribable:internalExtendedAttributeSubscribable];
  }];
}
- (id<RACSubscribable>)extendedAttributeForKey:(NSString *)key {
  return [[self class] coordinateSubscribable:[self internalExtendedAttributeForKey:key]];
}

- (id<RACSubscribable>)bindExtendedAttributeForKey:(NSString *)key to:(id<RACSubscribable>)extendedAttributeSubscribable {
  return [[self class] coordinateSubscribable:[self internalBindExtendedAttributeForKey:key to:[extendedAttributeSubscribable deliverOn:[[self class] fileSystemScheduler]]]];
}

@end

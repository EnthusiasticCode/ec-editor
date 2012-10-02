//
//  FileSystemFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemFile.h"
#import "FileSystemItem_Internal.h"
#import "RACEchoSubject.h"

@interface FileSystemFile ()

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong) NSData *contentBacking;

// Only called/subscribed/delivers on fileSystemScheduler
@property (nonatomic, strong, readonly) RACEchoSubject *contentEcho;

// Must be called and delivers on fileSystemScheduler
// The returned subscribable is sent tuples where the first element is the new content, and the second element is the subscribable that sent it originally if applicable
- (id<RACSubscribable>)internalContent;

// Must be called and delivers on fileSystemScheduler
- (id<RACSubscribable>)internalBindContentTo:(id<RACSubscribable>)internalContentSubscribable;

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

// Only called/bound/observed on fileSystemScheduler
// Contained subjects: only called/subscribed/delivers on fileSystemScheduler
@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesEchoes;

// Must be called on fileSystemScheduler
- (RACEchoSubject *)extendedAttributeEchoForKey:(NSString *)key;

// Must be called and delivers on fileSystemScheduler
// The returned subscribable is sent tuples where the first element is the new value, and the second element is the subscribable that sent it originally if applicable
- (id<RACSubscribable>)internalExtendedAttributeForKey:(NSString *)key;

// Must be called and delivers on fileSystemScheduler
- (id<RACSubscribable>)internalBindExtendedAttributeForKey:(NSString *)key to:(id<RACSubscribable>)internalExtendedAttributeSubscribable;

@end

@implementation FileSystemFile

@synthesize contentEcho = _contentEcho, extendedAttributesBacking = _extendedAttributesBacking, extendedAttributesEchoes = _extendedAttributesEchoes;

- (RACEchoSubject *)contentEcho {
  ASSERT_NOT_MAIN_QUEUE();
  if (!_contentEcho) {
    _contentEcho = [RACEchoSubject replaySubjectWithCapacity:1];
    [_contentEcho sendNext:self.contentBacking];
    RAC(self.contentBacking) = _contentEcho;
  }
  return _contentEcho;
}

- (id<RACSubscribable>)internalContent {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    return self.contentEcho;
  }];
}

- (id<RACSubscribable>)internalBindContentTo:(id<RACSubscribable>)internalContentSubscribable {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    return [self.contentEcho echoSubscribable:internalContentSubscribable];
  }];
}

- (NSMutableDictionary *)extendedAttributesBacking {
  ASSERT_NOT_MAIN_QUEUE();
  if (!_extendedAttributesBacking) {
    _extendedAttributesBacking = [NSMutableDictionary dictionary];
  }
  return _extendedAttributesBacking;
}

- (NSMutableDictionary *)extendedAttributesEchoes {
  ASSERT_NOT_MAIN_QUEUE();
  if (!_extendedAttributesEchoes) {
    _extendedAttributesEchoes = [NSMutableDictionary dictionary];
  }
  return _extendedAttributesEchoes;
}

- (RACEchoSubject *)extendedAttributeEchoForKey:(NSString *)key {
  ASSERT_NOT_MAIN_QUEUE();
  RACEchoSubject *echo = [self.extendedAttributesEchoes objectForKey:key];
  if (!echo) {
    echo = [RACEchoSubject replaySubjectWithCapacity:1];
    [echo sendNext:[self.extendedAttributesBacking objectForKey:key]];
    [self.extendedAttributesEchoes setObject:echo forKey:key];
    __weak FileSystemFile *weakSelf = self;
    [echo subscribeNext:^(id x) {
      __strong FileSystemFile *strongSelf = weakSelf;
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

- (id<RACSubscribable>)content {
  return [[self class] coordinateSubscribable:[self internalContent]];
}

- (id<RACSubscribable>)bindContentTo:(id<RACSubscribable>)contentSubscribable {
  return [[self class] coordinateSubscribable:[self internalBindContentTo:[contentSubscribable deliverOn:[[self class] fileSystemScheduler]]]];
}

- (id<RACSubscribable>)extendedAttributeForKey:(NSString *)key {
  return [[self class] coordinateSubscribable:[self internalExtendedAttributeForKey:key]];
}

- (id<RACSubscribable>)bindExtendedAttributeForKey:(NSString *)key to:(id<RACSubscribable>)extendedAttributeSubscribable {
  return [[self class] coordinateSubscribable:[self internalBindExtendedAttributeForKey:key to:[extendedAttributeSubscribable deliverOn:[[self class] fileSystemScheduler]]]];
}

@end

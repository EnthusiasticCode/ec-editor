//
//  FileSystemDirectory.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemDirectory_Internal.h"
#import "FileSystemItem_Internal.h"


@implementation FileSystemDirectory

- (id<RACSubscribable>)internalContent {
  return [self internalContentWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (id<RACSubscribable>)internalContentWithOptions:(NSDirectoryEnumerationOptions)options {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    if (!self.itemURLBacking) {
      return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendError:[[NSError alloc] init]];
        return [RACDisposable disposableWithBlock:nil];
      }];
    }
    RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:1];
    NSMutableArray *content = [NSMutableArray array];
    for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:self.itemURLBacking includingPropertiesForKeys:nil options:options errorHandler:nil]) {
      [content addObject:childURL];
    }
    [subject sendNext:content];
    return subject;
  }];
}

@end

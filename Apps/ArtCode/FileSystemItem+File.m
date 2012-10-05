//
//  FileSystemFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem+File.h"
#import "FileSystemItem_Internal.h"
#import "RACPropertySyncSubject.h"


static NSStringEncoding _defaultEncoding = NSUTF8StringEncoding;


@implementation FileSystemItem (File)

- (RACPropertySyncSubject *)content {
  RACPropertySyncSubject *content = self.contentSubject;
  if (!content) {
    content = [RACPropertySyncSubject subject];
    [[content deliverOn:[[self class] fileSystemScheduler]] toProperty:RAC_KEYPATH_SELF(contentBacking) onObject:self];
    self.contentSubject = content;
  }
  return content;
}

- (RACPropertySyncSubject *)contentWithDefaultEncoding {
  return [self contentWithEncoding:_defaultEncoding];
}

- (RACPropertySyncSubject *)contentWithEncoding:(NSStringEncoding)encoding {
  RACPropertySyncSubject *content = [self.contentSubjects objectForKey:@(encoding)];
  if (!content) {
    content = [RACPropertySyncSubject subject];
    [[[content deliverOn:[[self class] fileSystemScheduler]] select:^NSData *(NSString *string) {
      return [string dataUsingEncoding:encoding];
    }] toProperty:RAC_KEYPATH_SELF(contentBacking) onObject:self];
    [self.contentSubjects setObject:content forKey:@(encoding)];
  }
  return content;
}

@end

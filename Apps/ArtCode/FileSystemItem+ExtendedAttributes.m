//
//  FileSystemItem+ExtendedAttributes.m
//  ArtCode
//
//  Created by Uri Baghin on 10/4/12.
//
//

#import "FileSystemItem+ExtendedAttributes.h"
#import "FileSystemItem_Internal.h"
#import "RACPropertySyncSubject.h"


@implementation FileSystemItem (ExtendedAttributes)

- (RACPropertySyncSubject *)extendedAttributeForKey:(NSString *)key {
  RACPropertySyncSubject *extendedAttribute = [self.extendedAttributeSubjects objectForKey:key];
  if (!extendedAttribute) {
    extendedAttribute = [RACPropertySyncSubject subject];
    [[extendedAttribute deliverOn:[[self class] fileSystemScheduler]] subscribeNext:^(id x) {
      if (x) {
        [self.extendedAttributesBacking setObject:x forKey:key];
      } else {
        [self.extendedAttributesBacking removeObjectForKey:x];
      }
    }];
    [self.extendedAttributeSubjects setObject:extendedAttribute forKey:key];
  }
  return extendedAttribute;
}

@end

//
//  FileBuffer.m
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FileBuffer.h"
#import "ACProjectFile.h"
#import "ACProject.h"

#pragma mark -
@implementation FileBuffer {
  NSMutableAttributedString *_contents;
  NSMutableArray *_presenters;
}

@synthesize defaultAttributes = _defaultAttributes, fileURL = _fileURL;

#pragma mark - NSObject

- (id)init {
  return [self initWithFileURL:nil];
}

#pragma mark - Public methods

- (void)setDefaultAttributes:(NSDictionary *)defaultAttributes {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);

  NSRange range = NSMakeRange(0, self.length);

  @synchronized(_contents) {
    if (defaultAttributes == _defaultAttributes) {
      return;
    }
    if (range.length && _defaultAttributes.count) {
      for (NSString *attributeName in _defaultAttributes.allKeys) {
        [_contents removeAttribute:attributeName range:range];
      }
    }
    _defaultAttributes = defaultAttributes;
    if (range.length && defaultAttributes.count) {
      [self addAttributes:defaultAttributes range:range];
    }
  }
  
  for (id<FileBufferPresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(fileBuffer:didChangeAttributesInRange:)]) {
      [presenter fileBuffer:self didChangeAttributesInRange:range];
    }
  }
}

- (id)initWithFileURL:(NSURL *)fileURL {
  self = [super init];
  if (!self) {
    return nil;
  }
  _contents = NSMutableAttributedString.alloc.init;
  _presenters = NSMutableArray.alloc.init;
  return self;
}

- (void)addPresenter:(id<FileBufferPresenter>)presenter {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [_presenters addObject:presenter];
}

- (void)removePresenter:(id<FileBufferPresenter>)presenter {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [_presenters removeObject:presenter];
}

- (NSArray *)presenters {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  return _presenters.copy;
}

#pragma mark - String content reading methods

- (NSUInteger)length {
  @synchronized(_contents) {
    return _contents.length;
  }
}

- (NSString *)string {
  @synchronized(_contents) {
    return _contents.string;
  }
}

- (NSString *)substringWithRange:(NSRange)range {
  @synchronized(_contents) {
    return [_contents.string substringWithRange:range];
  }
}

- (NSRange)lineRangeForRange:(NSRange)range {
  @synchronized(_contents) {
    return [_contents.string lineRangeForRange:range];
  }
}

#pragma mark - Attributed string content reading methods

- (NSAttributedString *)attributedString {
  @synchronized(_contents) {
    return _contents.copy;
  }
}

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range {
  @synchronized(_contents) {
    return [_contents attributedSubstringFromRange:range];
  }
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
  @synchronized(_contents) {
    return [_contents attribute:attrName atIndex:location effectiveRange:range];
  }
}
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit {
  @synchronized(_contents) {
    return [_contents attribute:attrName atIndex:location longestEffectiveRange:range inRange:rangeLimit];
  }
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
  @synchronized(_contents) {
    return [_contents attributesAtIndex:location effectiveRange:range];
  }
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit {
  @synchronized(_contents) {
    return [_contents attributesAtIndex:location longestEffectiveRange:range inRange:rangeLimit];
  }
}

#pragma mark - String content writing methods

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  
  // replacing an empty range with an empty string, no change required
  if (!range.length && !string.length) {
    return;
  }
  
  // replacing a substring with an equal string, no change required
  if ([string isEqualToString:[self substringWithRange:range]]) {
    return;
  }
  
  // a nil string can be passed to delete characters
  if (!string) {
    string = @"";
  }
  
  NSAttributedString *attributedString = [NSAttributedString.alloc initWithString:string attributes:self.defaultAttributes];
  
  @synchronized(_contents) {
    if (attributedString.length) {
      [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    } else {
      [_contents deleteCharactersInRange:range];
    }
  }

  for (id<FileBufferPresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(fileBuffer:didReplaceCharactersInRange:withAttributedString:)]) {
      [presenter fileBuffer:self didReplaceCharactersInRange:range withAttributedString:attributedString];
    }
  }
}

#pragma mark - Attributed string content writing methods

- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)range {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  @synchronized(_contents) {
    [_contents addAttribute:name value:value range:range];
  }
  
  for (id<FileBufferPresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(fileBuffer:didChangeAttributesInRange:)]) {
      [presenter fileBuffer:self didChangeAttributesInRange:range];
    }
  }
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  @synchronized(_contents) {
    [_contents addAttributes:attributes range:range];
  }
  
  for (id<FileBufferPresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(fileBuffer:didChangeAttributesInRange:)]) {
      [presenter fileBuffer:self didChangeAttributesInRange:range];
    }
  }
}

- (void)removeAttribute:(NSString *)name range:(NSRange)range {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  @synchronized(_contents) {
    [_contents removeAttribute:name range:range];
  }
  
  for (id<FileBufferPresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(fileBuffer:didChangeAttributesInRange:)]) {
      [presenter fileBuffer:self didChangeAttributesInRange:range];
    }
  }
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  @synchronized(_contents) {
    [_contents setAttributes:attributes range:range];
  }

  for (id<FileBufferPresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(fileBuffer:didChangeAttributesInRange:)]) {
      [presenter fileBuffer:self didChangeAttributesInRange:range];
    }
  }
}

@end

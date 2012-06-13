//
//  NSAttributedString+PersistentDataStructures.m
//  ArtCode
//
//  Created by Uri Baghin on 23/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSAttributedString+PersistentDataStructures.h"

@implementation NSAttributedString (PersistentDataStructures)

- (NSAttributedString *)attributedStringBySettingAttributes:(NSDictionary *)attributes range:(NSRange)range {
  NSMutableAttributedString *attributedString = self.mutableCopy;
  [attributedString setAttributes:attributes range:range];
  return attributedString.copy;
}

- (NSAttributedString *)attributedStringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)string {
  NSMutableAttributedString *attributedString = self.mutableCopy;
  [attributedString replaceCharactersInRange:range withString:string];
  return attributedString.copy;
}

@end

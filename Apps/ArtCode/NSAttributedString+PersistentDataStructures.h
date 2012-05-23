//
//  NSAttributedString+PersistentDataStructures.h
//  ArtCode
//
//  Created by Uri Baghin on 23/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (PersistentDataStructures)

- (NSAttributedString *)attributedStringBySettingAttributes:(NSDictionary *)attributes range:(NSRange)range;

@end

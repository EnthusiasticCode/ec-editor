//
//  NSDictionary+Additions.h
//  Foundation
//
//  Created by Nicola Peduzzi on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Additions)

+ (NSDictionary *)dictionaryWithURLEncodedString:(NSString *)encodedString;
- (NSString *)stringWithURLEncodedComponents;

@end

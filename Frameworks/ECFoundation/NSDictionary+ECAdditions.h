//
//  NSDictionary+ECAdditions.h
//  ECFoundation
//
//  Created by Nicola Peduzzi on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ECAdditions)

+ (NSDictionary *)dictionaryWithURLEncodedString:(NSString *)encodedString;
- (NSString *)stringWithURLEncodedComponents;

@end

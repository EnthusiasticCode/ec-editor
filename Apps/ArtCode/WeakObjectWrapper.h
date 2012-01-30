//
//  WeakObjectWrapper.h
//  Foundation
//
//  Created by Uri Baghin on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WeakObjectWrapper : NSObject
{
    @package
    __weak id object;
}
+ (WeakObjectWrapper *)wrapperWithObject:(id)object;
@end

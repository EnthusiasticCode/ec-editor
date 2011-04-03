//
//  ECHashing.c
//  ECFoundation
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECHashing.h"
#import "MurmurHash3.h"

NSUInteger ECHashNSUIntegers(NSUInteger *values, NSUInteger count)
{
    NSUInteger hash;
    const uint32_t random_seed = 1691597231;
    MurmurHash3_x86_32(values, count * sizeof(NSUInteger), random_seed, &hash);
    return hash;
}

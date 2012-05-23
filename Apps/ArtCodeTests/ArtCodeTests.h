//
//  ArtCodeTests.h
//  ArtCode
//
//  Created by Uri Baghin on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

void clearProjectsDirectory(void);

// Redefine the default timeout because my iMac is so slow
#undef kKW_DEFAULT_PROBE_TIMEOUT
#define kKW_DEFAULT_PROBE_TIMEOUT 10

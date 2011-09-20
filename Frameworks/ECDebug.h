//
//  ECDebug.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef ECDebug_h
#define ECDebug_h

#include <assert.h>

#if DEBUG
#define ECASSERT(a) assert(a)
#else
#define ECASSERT(a)
#endif


#define UNIMPLEMENTED_VOID() [NSException raise:NSGenericException format:@"Message %@ sent to instance of class %@, which does not implement that method", NSStringFromSelector(_cmd), [[self class] description]]

#define UNIMPLEMENTED() UNIMPLEMENTED_VOID(); return 0

#if DEBUG
#define REQUIRE_NOT_NULL(a) do { \
if ((a)==NULL) {\
fprintf(stderr, "REQUIRE_NOT_NULL failed: NULL value for parameter " #a " on line %d in file %s\n", __LINE__, __FILE__);\
abort();\
}\
} while (0)

#define EXPECT_CLASS(e, c) do { \
if (! [(e) isKindOfClass:[c class]]) {\
fprintf(stderr, "EXPECT_CLASS failed: Expression " #e " is %s on line %d in file %s\n", (e) ? "(nil)" : [[e description] UTF8String], __LINE__, __FILE__);\
abort();\
}\
} while (0)

#else
#define REQUIRE_NOT_NULL(a)
#define EXPECT_CLASS(e, c)
#endif

#endif

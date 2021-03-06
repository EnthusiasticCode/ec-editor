#ifndef __DEBUG_H__
#define __DEBUG_H__

// C Debug Macros
#if DEBUG
#include <assert.h>
#define ASSERT(a) assert(a)

#define REQUIRE_NOT_NULL(a) do { \
if ((a)==NULL) {\
fprintf(stderr, "REQUIRE_NOT_NULL failed: NULL value for parameter " #a " on line %d in file %s\n", __LINE__, __FILE__);\
abort();\
}\
} while (0)

#else
#define ASSERT(a) // if (0 && ! (a)) abort()
#define REQUIRE_NOT_NULL(a)
#endif


#ifdef __OBJC__

// ObjC General Macros
#define UNIMPLEMENTED_VOID() [NSException raise:NSGenericException \
format:@"Message %@ sent to instance of class %@, "\
@"which does not implement that method",\
NSStringFromSelector(_cmd), [[self class] description]]

#define UNIMPLEMENTED() UNIMPLEMENTED_VOID(); return 0

#define ASSERT_MAIN_QUEUE() ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue])
#define ASSERT_NOT_MAIN_QUEUE() ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue])

// TODO: move to a more appropriate header
#define L(key) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

// ObjC Debug Macros
#if DEBUG

#define EXPECT_CLASS(e, c) do { \
if (! [(e) isKindOfClass:[c class]]) {\
fprintf(stderr, "EXPECT_CLASS failed: Expression " #e " is %s on line %d in file %s\n", (e) ? "(nil)" : [[e description] UTF8String], __LINE__, __FILE__);\
abort();\
}\
} while (0)

#else

#define EXPECT_CLASS(e, c)

#endif

#endif


#endif
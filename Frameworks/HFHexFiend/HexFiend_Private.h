//
// Prefix header for all source files of the 'HexFiend_2' target in the 'HexFiend_2' project
//

#ifdef __OBJC__
    #import "HFTypes.h"
#endif

#define PRIVATE_EXTERN __private_extern__

#include <assert.h>

#if ! NDEBUG
#define HFASSERT(a) assert(a)
#else
#define HFASSERT(a)
#endif


/* Macro to "use" a variable to prevent unused variable warnings. */
#define USE(x) if (0) x=x

#define check_malloc(x) ({ size_t _count = x; void* _result = malloc(_count); if (! _result) { fprintf(stderr, "Out of memory allocating %lu bytes\n", (unsigned long)_count); exit(EXIT_FAILURE); } _result; })
#define check_calloc(x) ({ size_t _count = x; void* _result = calloc(_count, 1); if (! _result) { fprintf(stderr, "Out of memory allocating %lu bytes\n", (unsigned long)_count); exit(EXIT_FAILURE); } _result; })

/* Create a stack or dynamic array of the given size.  This memory is NOT scanned and is NOT collected!  Anything you put in here must have external references! */
#define NEW_ARRAY(type, name, number) \
    type name ## static_ [256];\
    __strong type * name = ((number) <= 256 ? name ## static_ : (__unsafe_unretained type*)check_malloc((number) * sizeof(type)))
    
#define FREE_ARRAY(name) \
    if (name != name ## static_) free(name)

#if !defined(MIN)
    #define MIN(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
#endif

#if !defined(MAX)
    #define MAX(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __b : __a; })
#endif

//How many bytes should we read at a time when doing a find/replace?
#define SEARCH_CHUNK_SIZE 32768

//What's the smallest clipboard data size we should offer to avoid copying when quitting?  This is 5 MB
#define MINIMUM_PASTEBOARD_SIZE_TO_WARN_ABOUT (5UL << 20)

//What's the largest clipboard data size we should support exporting (at all?)  This is 500 MB.  Note that we can still copy more data than this internally, we just can't put it in, say, TextEdit.
#define MAXIMUM_PASTEBOARD_SIZE_TO_EXPORT (500UL << 20)

// When we save a file, and other byte arrays need to break their dependencies on the file by copying some of its data into memory, what's the max amount we should copy (per byte array)?  We currently don't show any progress for this, so this should be a smaller value
#define MAX_MEMORY_TO_USE_FOR_BREAKING_FILE_DEPENDENCIES_ON_SAVE (16 * 1024 * 1024)

#ifdef __OBJC__
    #import "HFFunctions.h"
    #import "HFFunctions_Private.h"
#endif
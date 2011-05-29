//
//  ECCodeCursor.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeUnit.h"

typedef enum
{
    ECCodeCursorKindUnknown                       = 0,
    /* Declarations */
    /**
     * \brief A declaration whose specific kind is not exposed via this
     * interface.
     *
     * Unexposed declarations have the same operations as any other kind
     * of declaration; one can extract their location information,
     * spelling, find their definitions, etc. However, the specific kind
     * of the declaration is not reported.
     */
    ECCodeCursorKindUnexposedDecl                 = 1,
    /** \brief A C or C++ struct. */
    ECCodeCursorKindStructDecl                    = 2,
    /** \brief A C or C++ union. */
    ECCodeCursorKindUnionDecl                     = 3,
    /** \brief A C++ class. */
    ECCodeCursorKindClassDecl                     = 4,
    /** \brief An enumeration. */
    ECCodeCursorKindEnumDecl                      = 5,
    /**
     * \brief A field (in C) or non-static data member (in C++) in a
     * struct, union, or C++ class.
     */
    ECCodeCursorKindFieldDecl                     = 6,
    /** \brief An enumerator constant. */
    ECCodeCursorKindEnumConstantDecl              = 7,
    /** \brief A function. */
    ECCodeCursorKindFunctionDecl                  = 8,
    /** \brief A variable. */
    ECCodeCursorKindVarDecl                       = 9,
    /** \brief A function or method parameter. */
    ECCodeCursorKindParmDecl                      = 10,
    /** \brief An Objective-C @interface. */
    ECCodeCursorKindObjCInterfaceDecl             = 11,
    /** \brief An Objective-C @interface for a category. */
    ECCodeCursorKindObjCCategoryDecl              = 12,
    /** \brief An Objective-C @protocol declaration. */
    ECCodeCursorKindObjCProtocolDecl              = 13,
    /** \brief An Objective-C @property declaration. */
    ECCodeCursorKindObjCPropertyDecl              = 14,
    /** \brief An Objective-C instance variable. */
    ECCodeCursorKindObjCIvarDecl                  = 15,
    /** \brief An Objective-C instance method. */
    ECCodeCursorKindObjCInstanceMethodDecl        = 16,
    /** \brief An Objective-C class method. */
    ECCodeCursorKindObjCClassMethodDecl           = 17,
    /** \brief An Objective-C @implementation. */
    ECCodeCursorKindObjCImplementationDecl        = 18,
    /** \brief An Objective-C @implementation for a category. */
    ECCodeCursorKindObjCCategoryImplDecl          = 19,
    /** \brief A typedef */
    ECCodeCursorKindTypedefDecl                   = 20,
    /** \brief A C++ class method. */
    ECCodeCursorKindCXXMethod                     = 21,
    /** \brief A C++ namespace. */
    ECCodeCursorKindNamespace                     = 22,
    /** \brief A linkage specification, e.g. 'extern "C"'. */
    ECCodeCursorKindLinkageSpec                   = 23,
    /** \brief A C++ constructor. */
    ECCodeCursorKindConstructor                   = 24,
    /** \brief A C++ destructor. */
    ECCodeCursorKindDestructor                    = 25,
    /** \brief A C++ conversion function. */
    ECCodeCursorKindConversionFunction            = 26,
    /** \brief A C++ template type parameter. */
    ECCodeCursorKindTemplateTypeParameter         = 27,
    /** \brief A C++ non-type template parameter. */
    ECCodeCursorKindNonTypeTemplateParameter      = 28,
    /** \brief A C++ template template parameter. */
    ECCodeCursorKindTemplateTemplateParameter     = 29,
    /** \brief A C++ function template. */
    ECCodeCursorKindFunctionTemplate              = 30,
    /** \brief A C++ class template. */
    ECCodeCursorKindClassTemplate                 = 31,
    /** \brief A C++ class template partial specialization. */
    ECCodeCursorKindClassTemplatePartialSpecialization = 32,
    /** \brief A C++ namespace alias declaration. */
    ECCodeCursorKindNamespaceAlias                = 33,
    /** \brief A C++ using directive. */
    ECCodeCursorKindUsingDirective                = 34,
    /** \brief A C++ using declaration. */
    ECCodeCursorKindUsingDeclaration              = 35,
    /** \brief A C++ alias declaration */
    ECCodeCursorKindTypeAliasDecl                 = 36,
    ECCodeCursorKindFirstDecl                     = ECCodeCursorKindUnexposedDecl,
    ECCodeCursorKindLastDecl                      = ECCodeCursorKindTypeAliasDecl,
    
    /* References */
    ECCodeCursorKindFirstRef                      = 40, /* Decl references */
    ECCodeCursorKindObjCSuperClassRef             = 40,
    ECCodeCursorKindObjCProtocolRef               = 41,
    ECCodeCursorKindObjCClassRef                  = 42,
    /**
     * \brief A reference to a type declaration.
     *
     * A type reference occurs anywhere where a type is named but not
     * declared. For example, given:
     *
     * \code
     * typedef unsigned size_type;
     * size_type size;
     * \endcode
     *
     * The typedef is a declaration of size_type (ECCodeCursorKindTypedefDecl),
     * while the type of the variable "size" is referenced. The cursor
     * referenced by the type of size is the typedef for size_type.
     */
    ECCodeCursorKindTypeRef                       = 43,
    ECCodeCursorKindCXXBaseSpecifier              = 44,
    /** 
     * \brief A reference to a class template, function template, template
     * template parameter, or class template partial specialization.
     */
    ECCodeCursorKindTemplateRef                   = 45,
    /**
     * \brief A reference to a namespace or namespace alias.
     */
    ECCodeCursorKindNamespaceRef                  = 46,
    /**
     * \brief A reference to a member of a struct, union, or class that occurs in 
     * some non-expression context, e.g., a designated initializer.
     */
    ECCodeCursorKindMemberRef                     = 47,
    /**
     * \brief A reference to a labeled statement.
     *
     * This cursor kind is used to describe the jump to "start_over" in the 
     * goto statement in the following example:
     *
     * \code
     *   start_over:
     *     ++counter;
     *
     *     goto start_over;
     * \endcode
     *
     * A label reference cursor refers to a label statement.
     */
    ECCodeCursorKindLabelRef                      = 48,
    
    /**
     * \brief A reference to a set of overloaded functions or function templates
     * that has not yet been resolved to a specific function or function template.
     *
     * An overloaded declaration reference cursor occurs in C++ templates where
     * a dependent name refers to a function. For example:
     *
     * \code
     * template<typename T> void swap(T&, T&);
     *
     * struct X { ... };
     * void swap(X&, X&);
     *
     * template<typename T>
     * void reverse(T* first, T* last) {
     *   while (first < last - 1) {
     *     swap(*first, *--last);
     *     ++first;
     *   }
     * }
     *
     * struct Y { };
     * void swap(Y&, Y&);
     * \endcode
     *
     * Here, the identifier "swap" is associated with an overloaded declaration
     * reference. In the template definition, "swap" refers to either of the two
     * "swap" functions declared above, so both results will be available. At
     * instantiation time, "swap" may also refer to other functions found via
     * argument-dependent lookup (e.g., the "swap" function at the end of the
     * example).
     *
     * The functions \c clang_getNumOverloadedDecls() and 
     * \c clang_getOverloadedDecl() can be used to retrieve the definitions
     * referenced by this cursor.
     */
    ECCodeCursorKindOverloadedDeclRef             = 49,
    
    ECCodeCursorKindLastRef                       = ECCodeCursorKindOverloadedDeclRef,
    
    /* Error conditions */
    ECCodeCursorKindFirstInvalid                  = 70,
    ECCodeCursorKindInvalidFile                   = 70,
    ECCodeCursorKindNoDeclFound                   = 71,
    ECCodeCursorKindNotImplemented                = 72,
    ECCodeCursorKindInvalidCode                   = 73,
    ECCodeCursorKindLastInvalid                   = ECCodeCursorKindInvalidCode,
    
    /* Expressions */
    ECCodeCursorKindFirstExpr                     = 100,
    
    /**
     * \brief An expression whose specific kind is not exposed via this
     * interface.
     *
     * Unexposed expressions have the same operations as any other kind
     * of expression; one can extract their location information,
     * spelling, children, etc. However, the specific kind of the
     * expression is not reported.
     */
    ECCodeCursorKindUnexposedExpr                 = 100,
    
    /**
     * \brief An expression that refers to some value declaration, such
     * as a function, varible, or enumerator.
     */
    ECCodeCursorKindDeclRefExpr                   = 101,
    
    /**
     * \brief An expression that refers to a member of a struct, union,
     * class, Objective-C class, etc.
     */
    ECCodeCursorKindMemberRefExpr                 = 102,
    
    /** \brief An expression that calls a function. */
    ECCodeCursorKindCallExpr                      = 103,
    
    /** \brief An expression that sends a message to an Objective-C
     object or class. */
    ECCodeCursorKindObjCMessageExpr               = 104,
    
    /** \brief An expression that represents a block literal. */
    ECCodeCursorKindBlockExpr                     = 105,
    
    ECCodeCursorKindLastExpr                      = 105,
    
    /* Statements */
    ECCodeCursorKindFirstStmt                     = 200,
    /**
     * \brief A statement whose specific kind is not exposed via this
     * interface.
     *
     * Unexposed statements have the same operations as any other kind of
     * statement; one can extract their location information, spelling,
     * children, etc. However, the specific kind of the statement is not
     * reported.
     */
    ECCodeCursorKindUnexposedStmt                 = 200,
    
    /** \brief A labelled statement in a function. 
     *
     * This cursor kind is used to describe the "start_over:" label statement in 
     * the following example:
     *
     * \code
     *   start_over:
     *     ++counter;
     * \endcode
     *
     */
    ECCodeCursorKindLabelStmt                     = 201,
    
    ECCodeCursorKindLastStmt                      = ECCodeCursorKindLabelStmt,
    
    /**
     * \brief Cursor that represents the translation unit itself.
     *
     * The translation unit cursor exists primarily to act as the root
     * cursor for traversing the contents of a translation unit.
     */
    ECCodeCursorKindTranslationUnit               = 300,
    
    /* Attributes */
    ECCodeCursorKindFirstAttr                     = 400,
    /**
     * \brief An attribute whose specific kind is not exposed via this
     * interface.
     */
    ECCodeCursorKindUnexposedAttr                 = 400,
    
    ECCodeCursorKindIBActionAttr                  = 401,
    ECCodeCursorKindIBOutletAttr                  = 402,
    ECCodeCursorKindIBOutletCollectionAttr        = 403,
    ECCodeCursorKindLastAttr                      = ECCodeCursorKindIBOutletCollectionAttr,
    
    /* Preprocessing */
    ECCodeCursorKindPreprocessingDirective        = 500,
    ECCodeCursorKindMacroDefinition               = 501,
    ECCodeCursorKindMacroInstantiation            = 502,
    ECCodeCursorKindInclusionDirective            = 503,
    ECCodeCursorKindFirstPreprocessing            = ECCodeCursorKindPreprocessingDirective,
    ECCodeCursorKindLastPreprocessing             = ECCodeCursorKindInclusionDirective
} ECCodeCursorKind;

@interface ECCodeCursor : NSObject
@property (nonatomic, readonly, retain) ECCodeUnit *codeUnit;
@property (nonatomic, readonly, copy) NSString *language;
@property (nonatomic, readonly) ECCodeCursorKind kind;
@property (nonatomic, readonly, copy) NSString *detailedKind;
@property (nonatomic, readonly, copy) NSString *spelling;
@property (nonatomic, readonly, copy) NSString *file;
@property (nonatomic, readonly) NSUInteger offset;
@property (nonatomic, readonly) NSRange extent;
@property (nonatomic, readonly, copy) NSString *unifiedSymbolResolution;
- (id)initWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution;
+ (id)cursorWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution;
@end

//
//  ClangHelperFunctions.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangHelperFunctions.h"

NSUInteger Clang_SourceLocationOffset(CXSourceLocation clangSourceLocation, NSURL *__autoreleasing *fileURL)
{
    if (clang_equalLocations(clangSourceLocation, clang_getNullLocation()))
        return NSNotFound;
    CXFile clangFile;
    unsigned clangOffset;
    clang_getInstantiationLocation(clangSourceLocation, &clangFile, NULL, NULL, &clangOffset);
    if (fileURL)
    {
        CXString clangFileName = clang_getFileName(clangFile);
        if (clang_getCString(clangFileName))
            *fileURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:clang_getCString(clangFileName)]];
        else
            *fileURL = nil;
        clang_disposeString(clangFileName);
    }
    return clangOffset;
}

NSRange Clang_SourceRangeRange(CXSourceRange clangSourceRange, NSURL *__autoreleasing *fileURL)
{
    if (clang_equalRanges(clangSourceRange, clang_getNullRange()))
        return NSMakeRange(NSNotFound, 0);
    NSUInteger start = Clang_SourceLocationOffset(clang_getRangeStart(clangSourceRange), fileURL);
    NSUInteger end = Clang_SourceLocationOffset(clang_getRangeEnd(clangSourceRange), NULL);
    ECASSERT(end > start);
    return NSMakeRange(start, end - start);
}

NSString *Clang_CursorKindScopeIdentifier(enum CXCursorKind cursorKind)
{
    switch (cursorKind)
    {
            // Declarations:
        case CXCursor_UnexposedDecl:
            return @"meta.declaration.unexposed";
        case CXCursor_StructDecl:
            return @"meta.struct";
        case CXCursor_UnionDecl:
            return @"meta.union";
        case CXCursor_ClassDecl:
            return @"meta.class";
        case CXCursor_EnumDecl:
            return @"meta.enum";
        case CXCursor_FieldDecl:
            return @"meta.field";
        case CXCursor_EnumConstantDecl:
            return @"meta.constant";
        case CXCursor_FunctionDecl:
            return @"meta.function";
        case CXCursor_VarDecl:
            return @"meta.variable";
        case CXCursor_ParmDecl:
            return @"meta.function.parameter";
        case CXCursor_ObjCInterfaceDecl:
            return @"meta.interface.class";
        case CXCursor_ObjCCategoryDecl:
            return @"meta.interface.category";
        case CXCursor_ObjCProtocolDecl:
            return @"meta.protocol";
        case CXCursor_ObjCPropertyDecl:
            return @"meta.class.property";
        case CXCursor_ObjCIvarDecl:
            return @"meta.class.instance-variable";
        case CXCursor_ObjCInstanceMethodDecl:
            return @"meta.function.instance-method";
        case CXCursor_ObjCClassMethodDecl:
            return @"meta.function.class-method";
        case CXCursor_ObjCImplementationDecl:
            return @"meta.implementation.class";
        case CXCursor_ObjCCategoryImplDecl:
            return @"meta.implementation.category";
        case CXCursor_TypedefDecl:
            return @"meta.typedef";
        case CXCursor_CXXMethod:
            return @"meta.function.class-method";
        case CXCursor_Namespace:
            return @"meta.namespace";
        case CXCursor_LinkageSpec:
            return @"meta.linkage-specification";
        case CXCursor_Constructor:
            return @"meta.function.constructor";
        case CXCursor_Destructor:
            return @"meta.function.destructor";
        case CXCursor_ConversionFunction:
            return @"meta.function.conversion";
        case CXCursor_TemplateTypeParameter:
            return @"meta.template.parameter.type";
        case CXCursor_NonTypeTemplateParameter:
            return @"meta.template.parameter.non-type";
        case CXCursor_TemplateTemplateParameter:
            return @"meta.template.parameter.template";
        case CXCursor_FunctionTemplate:
            return @"meta.template.function";
        case CXCursor_ClassTemplate:
            return @"meta.template.class";
        case CXCursor_ClassTemplatePartialSpecialization:
            return @"meta.template.class.partial-specialization";
        case CXCursor_NamespaceAlias:
            return @"meta.namespace.alias";
        case CXCursor_UsingDirective:
            return @"meta.using.directive";
        case CXCursor_UsingDeclaration:
            return @"meta.using";
        case CXCursor_TypeAliasDecl:
            return @"meta.alias";
        case CXCursor_ObjCSynthesizeDecl:
            return @"meta.class.property.synthesize";
        case CXCursor_ObjCDynamicDecl:
            return @"meta.class.property.dynamic";
        case CXCursor_CXXAccessSpecifier:
            return @"meta.access-specifier";
            // References:
        case CXCursor_ObjCSuperClassRef:
            return @"variable.language.super";
        case CXCursor_ObjCProtocolRef:
            return @"variable.other.protocol";
        case CXCursor_ObjCClassRef:
            return @"variable.other.class";
        case CXCursor_TypeRef:
            return @"variable.other.typedef";
        case CXCursor_CXXBaseSpecifier:
            return @"variable.language.base-specifier";
        case CXCursor_TemplateRef:
            return @"variable.other.template";
        case CXCursor_NamespaceRef:
            return @"variable.other.namespace";
        case CXCursor_MemberRef:
            return @"variable.other.member";
        case CXCursor_LabelRef:
            return @"variable.other.label";
        case CXCursor_OverloadedDeclRef:
            return @"variable.other.function.overloaded";
            // Error conditions
        case CXCursor_InvalidFile:
        case CXCursor_NoDeclFound:
        case CXCursor_NotImplemented:
            return @"invalid";
        case CXCursor_InvalidCode:
            return @"invalid.illegal";
            // Expressions
        case CXCursor_UnexposedExpr:
            return @"meta.expression.unexposed";
        case CXCursor_DeclRefExpr:
            return @"meta.expression.declaration";
        case CXCursor_MemberRefExpr:
            return @"variable.other.dot-access";
        case CXCursor_CallExpr:
            return @"meta.function-call";
        case CXCursor_ObjCMessageExpr:
            return @"meta.message-send";
        case CXCursor_BlockExpr:
            return @"meta.block-literal";
        case CXCursor_IntegerLiteral:
            return @"constant.numeric.integer";
        case CXCursor_FloatingLiteral:
            return @"constant.numeric.float";
        case CXCursor_ImaginaryLiteral:
            return @"constant.numeric.imaginary";
        case CXCursor_StringLiteral:
            return @"string.quoted";
        case CXCursor_CharacterLiteral:
            return @"constant.character";
        case CXCursor_ParenExpr:
            return @"meta.expression.parethesized";
        case CXCursor_UnaryOperator:
            return @"meta.expression.unary";
        case CXCursor_ArraySubscriptExpr:
            return @"meta.expression.subscript";
        case CXCursor_BinaryOperator:
            return @"meta.expression.binary";
        case CXCursor_CompoundAssignOperator:
            return @"meta.expression.compound-assignment";
        case CXCursor_ConditionalOperator:
            return @"meta.expression.conditional";
        case CXCursor_CStyleCastExpr:
            return @"meta.expression.typecast";
        case CXCursor_CompoundLiteralExpr:
            return @"meta.expression.compound-literal";
        case CXCursor_InitListExpr:
            return @"meta.expression.initializer-list";
        case CXCursor_AddrLabelExpr:
            return @"meta.expression.label.address";
        case CXCursor_StmtExpr:
            return @"meta.expression.statement";
        case CXCursor_GenericSelectionExpr:
            return @"meta.expression.generic-selection";
        case CXCursor_GNUNullExpr:
            return @"meta.expression.gnu-null";
        case CXCursor_CXXStaticCastExpr:
            return @"meta.expression.static-cast";
        case CXCursor_CXXDynamicCastExpr:
            return @"meta.expression.dynamic-cast";
        case CXCursor_CXXReinterpretCastExpr:
            return @"meta.expression.reinterpret-cast";
        case CXCursor_CXXConstCastExpr:
            return @"meta.expression.const-cast";
        case CXCursor_CXXFunctionalCastExpr:
            return @"meta.expression.functional-cast";
        case CXCursor_CXXTypeidExpr:
            return @"meta.expression.typeid";
        case CXCursor_CXXBoolLiteralExpr:
            return @"constant.other.boolean";
        case CXCursor_CXXNullPtrLiteralExpr:
            return @"constant.other.null-pointer";
        case CXCursor_CXXThisExpr:
            return @"costant.language.this";
        case CXCursor_CXXThrowExpr:
            return @"meta.expression.throw";
        case CXCursor_CXXNewExpr:
            return @"meta.expression.new";
        case CXCursor_CXXDeleteExpr:
            return @"meta.expression.delete";
        case CXCursor_UnaryExpr:
            return @"meta.expression.unary";
        case CXCursor_ObjCStringLiteral:
            return @"string.quoted.other";
        case CXCursor_ObjCEncodeExpr:
            return @"meta.expression.encode";
        case CXCursor_ObjCSelectorExpr:
            return @"meta.expression.selector";
        case CXCursor_ObjCProtocolExpr:
            return @"meta.expression.protocol";
        case CXCursor_ObjCBridgedCastExpr:
            return @"meta.expression.bridge";
        case CXCursor_PackExpansionExpr:
            return @"meta.expression.pack-expansion";
        case CXCursor_SizeOfPackExpr:
            return @"meta.expression.sizeof.pack";
            // Statements
        case CXCursor_UnexposedStmt:
            return @"meta.statement.unexposed";
        case CXCursor_LabelStmt:
            return @"meta.statement.control.label";
        case CXCursor_CompoundStmt:
            return @"meta.statement.compound";
        case CXCursor_CaseStmt:
            return @"meta.statement.control.switch.case";
        case CXCursor_DefaultStmt:
            return @"meta.statement.control.switch.default";
        case CXCursor_IfStmt:
            return @"meta.statement.control.if";
        case CXCursor_SwitchStmt:
            return @"meta.statement.control.switch";
        case CXCursor_WhileStmt:
            return @"meta.statement.control.while";
        case CXCursor_DoStmt:
            return @"meta.statement.control.do";
        case CXCursor_ForStmt:
            return @"meta.statement.control.for";
        case CXCursor_GotoStmt:
            return @"meta.statement.control.goto";
        case CXCursor_IndirectGotoStmt:
            return @"meta.statement.control.goto.indirect";
        case CXCursor_ContinueStmt:
            return @"meta.statement.control.continue";
        case CXCursor_BreakStmt:
            return @"meta.statement.control.break";
        case CXCursor_ReturnStmt:
            return @"meta.statement.control.return";
        case CXCursor_AsmStmt:
            return @"meta.statement.asm";
        case CXCursor_ObjCAtTryStmt:
            return @"meta.statement.exception.try-catch";
        case CXCursor_ObjCAtCatchStmt:
            return @"meta.statement.exception.catch";
        case CXCursor_ObjCAtFinallyStmt:
            return @"meta.statement.exception.finally";
        case CXCursor_ObjCAtThrowStmt:
            return @"meta.statement.exception.throw";
        case CXCursor_ObjCAtSynchronizedStmt:
            return @"meta.statement.synchronized";
        case CXCursor_ObjCAutoreleasePoolStmt:
            return @"meta.statement.autoreleasepool";
        case CXCursor_ObjCForCollectionStmt:
            return @"meta.statement.control.for.fast-enumeration";
        case CXCursor_CXXCatchStmt:
            return @"meta.statement.exception.catch";
        case CXCursor_CXXTryStmt:
            return @"meta.statement.exception.try";
        case CXCursor_CXXForRangeStmt:
            return @"meta.statement.control.for.range";
        case CXCursor_SEHTryStmt:
            return @"meta.statement.exception.try";
        case CXCursor_SEHExceptStmt:
            return @"meta.statement.exception.catch";
        case CXCursor_SEHFinallyStmt:
            return @"meta.statement.exception.finally";
        case CXCursor_NullStmt:
            return @"meta.statement.null-statement";
        case CXCursor_DeclStmt:
            return @"meta.statement.declaration";
        case CXCursor_TranslationUnit:
            return @"source";
            // Attributes
        case CXCursor_UnexposedAttr:
            return @"storage.modifier.unexposed";
        case CXCursor_IBActionAttr:
            return @"storage.modifier.ibaction";
        case CXCursor_IBOutletAttr:
            return @"storage.modifier.iboutlet";
        case CXCursor_IBOutletCollectionAttr:
            return @"storage.modifier.iboutlet.collection";
        case CXCursor_CXXFinalAttr:
            return @"storage.modifier.final";
        case CXCursor_CXXOverrideAttr:
            return @"storage.modifier.override";
            // Preprocessing
        case CXCursor_PreprocessingDirective:
            return @"meta.preprocessor";
        case CXCursor_MacroDefinition:
            return @"meta.preprocessor.macro.definition";
        case CXCursor_MacroInstantiation:
            return @"meta.preprocessor.macro.instantiation";
        case CXCursor_InclusionDirective:
            return @"meta.preprocessor.include";
    }
}
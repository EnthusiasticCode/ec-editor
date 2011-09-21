//
//  ACCompletionController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCompletionController.h"

#import <ECFoundation/ECPatriciaTrie.h>
#import <ECCodeIndexing/ECCodeCompletionResult.h>
#import <ECCodeIndexing/ECCodeCompletionString.h>
#import <ECCodeIndexing/ECCodeCompletionChunk.h>

#define TRIE_OPTIONS (ECPatriciaTrieEnumerationOptionsSkipRoot | ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord | ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch)

@implementation ACCompletionController {
    NSArray *filteredResults;
}

#pragma mark - Private Methods



#pragma mark - Properties

@synthesize resultSelectedBlock;


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [filteredResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    ECPatriciaTrie *node = [filteredResults objectAtIndex:indexPath.row];
    cell.textLabel.text = node.key;
    if (node.object)
    {
        NSMutableString *string = [NSMutableString string];
        for (ECCodeCompletionChunk *chunk in [[node.object completionString] completionChunks])
            [string appendString:chunk.string];
        cell.detailTextLabel.text = string;
        NSString *iconResource = nil;
        switch ([node.object cursorKind]) {
            case ECCodeCursorKindObjCClassRef:
            case ECCodeCursorKindObjCSuperClassRef:
            case ECCodeCursorKindClassDecl:
                iconResource = @"CodeAssistantClass";
                break;
            case ECCodeCursorKindObjCCategoryDecl:
            case ECCodeCursorKindObjCCategoryImplDecl:
                iconResource = @"CodeAssistantClassExtension";
                break;
            case ECCodeCursorKindVarDecl:
                iconResource = @"CodeAssistantVariable";
                break;
            case ECCodeCursorKindUnionDecl:
                iconResource = @"CodeAssistantUnion";
                break;
            case ECCodeCursorKindObjCProtocolRef:
            case ECCodeCursorKindObjCProtocolDecl:
                iconResource = @"CodeAssistantProtocol";
                break;
            case ECCodeCursorKindObjCPropertyDecl:
                iconResource = @"CodeAssistantProperty";
                break;
            case ECCodeCursorKindPreprocessingDirective:
            case ECCodeCursorKindMacroDefinition:
            case ECCodeCursorKindMacroInstantiation:
                iconResource = @"CodeAssistantMacro";
                break;
            case ECCodeCursorKindEnumDecl:
                iconResource = @"CodeAssistantEnum";
                break;
            case ECCodeCursorKindEnumConstantDecl:
                iconResource = @"CodeAssistantEnumConst";
                break;
            case ECCodeCursorKindFunctionDecl:
            case ECCodeCursorKindFunctionTemplate:
                iconResource = @"CodeAssistantFunction";
                break;
            case ECCodeCursorKindTypeRef:
                iconResource = @"CodeAssistantType";
                break;
            case ECCodeCursorKindFieldDecl:
                iconResource = @"CodeAssistantField";
                break;
            default:
                break;
        }
        if (iconResource)
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:iconResource ofType:@"tiff"]];
    }
    else
    {
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
    }
    
    if (![node nodeCountWithOptions:TRIE_OPTIONS])
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        if (node.object)
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    ECPatriciaTrie *node = [filteredResults objectAtIndex:indexPath.row];
//    if (!node.object && [node nodeCountWithOptions:TRIE_OPTIONS])
//        return [self setMatch:node.key];
//    if (!node.object)
//        return;
//    self.resultSelectedBlock(node.object);
//}
//
//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
//{
//    ECPatriciaTrie *node = [filteredResults objectAtIndex:indexPath.row];
//    if ([node count])
//        return [self setMatch:node.key];
//    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
//}

@end

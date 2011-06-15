//
//  CompletionController.m
//  edit
//
//  Created by Uri Baghin on 5/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CompletionController.h"

#import "ECPatriciaTrie.h"
#import "ECCodeCompletionResult.h"
#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"

static const ECPatriciaTrieEnumerationOptions _options = ECPatriciaTrieEnumerationOptionsSkipRoot | ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord | ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch;

@interface CompletionController ()
@property (nonatomic, strong) NSArray *filteredResults;
- (void)_filterResults;
@end

@implementation CompletionController

@synthesize results = _results;
@synthesize match = _match;
@synthesize filteredResults = _filteredResults;
@synthesize resultSelectedBlock = _resultSelectedBlock;

- (void)setResults:(ECPatriciaTrie *)results
{
    if (results == _results)
        return;
    _results = results;
    [self _filterResults];
    [self.tableView reloadData];
}

- (void)setMatch:(NSString *)match
{
    if ([match isEqualToString:_match])
        return;
    _match = match;
    [self _filterResults];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)_filterResults
{
    self.filteredResults = [self.results nodesForKeysStartingWithString:self.match options:_options];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    ECPatriciaTrie *node = [self.filteredResults objectAtIndex:indexPath.row];
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
    if (![node nodeCountWithOptions:_options])
        cell.accessoryType = UITableViewCellAccessoryNone;
    else
        if (node.object)
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ECPatriciaTrie *node = [self.filteredResults objectAtIndex:indexPath.row];
    if (!node.object && [node nodeCountWithOptions:_options])
        return [self setMatch:node.key];
    if (!node.object)
        return;
    self.resultSelectedBlock(node.object);
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    ECPatriciaTrie *node = [self.filteredResults objectAtIndex:indexPath.row];
    if ([node count])
        return [self setMatch:node.key];
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end

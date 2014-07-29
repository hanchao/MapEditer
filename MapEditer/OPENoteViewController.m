//
//  OPENoteViewController.m
//  OSM POI Editor
//
//  Created by David on 7/16/13.
//
//

#import "OPENoteViewController.h"
#import "OSMComment.h"
#import "OPECommentCell.h"
#import <QuartzCore/QuartzCore.h>
#import "DAKeyboardControl.h"
#import "OPEOSMAPIManager.h"
#import "OPEOSMData.h"
#import "OPENotesDatabase.h"
#import "OPEStrings.h"
#import "OPELog.h"

#define kChatBarHeight1                      40
#define kTextViewTag 101
#define kTableViewTag 102

@interface OPENoteViewController ()

@end

@implementation OPENoteViewController

-(id)initWithNote:(OSMNote *)newNote;
{
    if(self = [self init])
    {
        self.note = newNote;
        if (self.note.id > 0) {
            [OPENotesDatabase fetchNoteWithID:self.note.id completion:^(OSMNote *note) {
                self.note = note;
                [self reloadData];
            }];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    self.title = NOTE_STRING;
    
    CGRect tableViewRect = self.view.bounds;
    tableViewRect.size.height = tableViewRect.size.height - kChatBarHeight1;
    UITableView * tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.tag = kTableViewTag;
    UIEdgeInsets tableViewInsets = tableView.contentInset;
    tableViewInsets.bottom = tableViewInsets.bottom + kChatBarHeight1;
    tableView.contentInset = tableViewInsets;
    tableView.scrollIndicatorInsets = tableViewInsets;
    tableView.separatorColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIView * commentInputBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1)];
    commentInputBar.backgroundColor = [UIColor lightGrayColor];
    commentInputBar.layer.borderWidth = 1.0;
    commentInputBar.layer.borderColor = [UIColor darkGrayColor].CGColor;
    commentInputBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    UIButton * commentButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    commentButton.frame = CGRectMake(commentInputBar.frame.size.width - 70, 5, 70, kChatBarHeight1-10);
    [commentButton setTitle:@"Comment" forState:UIControlStateNormal];
    [commentButton addTarget:self action:@selector(commentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    commentButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [commentInputBar addSubview:commentButton];
    
    
    UITextView * textView = [[UITextView alloc] initWithFrame:CGRectMake(5, 5, commentInputBar.frame.size.width-10-commentButton.frame.size.width, kChatBarHeight1 -10)];
    textView.tag = kTextViewTag;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.delegate = self;
    textView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [commentInputBar addSubview:textView];
    
    
    [self.view addSubview:tableView];
    [self.view addSubview:commentInputBar];
    
    self.view.keyboardTriggerOffset = commentInputBar.frame.size.height;
    
    __weak OPENoteViewController * viewController = self;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        CGRect messageInputBarFrame = commentInputBar.frame;
        messageInputBarFrame.origin.y = keyboardFrameInView.origin.y - messageInputBarFrame.size.height;
        commentInputBar.frame = messageInputBarFrame;
        
        UIEdgeInsets insets = tableView.contentInset;
        
        
        insets.bottom = viewController.view.frame.size.height - commentInputBar.frame.origin.y;
        tableView.contentInset = insets;
        tableView.scrollIndicatorInsets = insets;
    }];
    
    UIBarButtonItem * cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    [self.navigationItem setLeftBarButtonItem:cancelButtonItem];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [OPENotesDatabase saveNote:self.note completion:nil];
    [self.view removeKeyboardControl];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.note.commentsArray count];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OPECommentCell heightForComment:[self.note.commentsArray objectAtIndex:indexPath.row]];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * tableViewCellIdentifier = @"tableViewCellIdentifier";
    OPECommentCell * cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellIdentifier];
    if (!cell) {
        cell = [[OPECommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableViewCellIdentifier];
    }
    OSMComment * comment = [self.note.commentsArray objectAtIndex:indexPath.row];
    cell.comment = comment;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self scrollToBottomAnimated:YES];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    UITableView * tableView = (UITableView *)[self.view viewWithTag:kTableViewTag];
    NSInteger numberOfRows = [tableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

-(BOOL)textViewHasTextLength
{
    if ([[self textViewStrippedText] length])
    {
        return YES;
    }
    return NO;
}
-(NSString *)textViewStrippedText
{
    UITextView * textView = (UITextView *)[self.view viewWithTag:kTextViewTag];
    return [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
-(void)clearTextViewText
{
    UITextView * textView = (UITextView *)[self.view viewWithTag:kTextViewTag];
    textView.text = @"";
}
-(void)reloadData
{
    UITableView * tableView = (UITableView *)[self.view viewWithTag:kTableViewTag];
    [tableView reloadData];
    
    // move last row
    NSUInteger sectionCount = [tableView numberOfSections];
    if (sectionCount) {
        
        NSUInteger rowCount = [tableView numberOfRowsInSection:sectionCount-1];
        if (rowCount) {
            
            NSUInteger indexs[2] = {sectionCount-1, rowCount - 1};
            NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:indexs length:2];
            [tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

-(void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)commentButtonPressed:(id)sender
{
    if (self.note.id == 0)
    {
        //new note
        void (^succesBlock)(id) =  ^(id JSON) {
            DDLogInfo(@"return data: %@",JSON);
            [self clearTextViewText];
            self.note = [self.osmData createNoteWithJSONDictionary:JSON];
            [self reloadData];
            [self scrollToBottomAnimated:YES];
        };
        
        OSMComment * comment = [[OSMComment alloc] init];
        comment.text = [self textViewStrippedText];
        [self.note addComment:comment];
        
        [self.osmApiManager createNewNote:self.note success:succesBlock failure:^(NSError *error) {
            DDLogError(@"error: %@",error);
        }];
    }else{
        if (self.note.isOpen){
            UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Comment", nil];
            
            [actionSheet addButtonWithTitle:@"Comment & Close"];
            [actionSheet addButtonWithTitle:@"Cancel"];
            
            actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
            [actionSheet showInView:self.view];
        }else{
            UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Comment & Reopen", nil];
            [actionSheet addButtonWithTitle:@"Cancel"];
            actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
            [actionSheet showInView:self.view];
        }
    }
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.note.isOpen){
        if (buttonIndex == 0) {
            // New Comment
            void (^succesBlock)(id) =  ^(id JSON) {
                DDLogInfo(@"return data: %@",JSON);
                [self clearTextViewText];
                self.note = [self.osmData createNoteWithJSONDictionary:JSON];
                [self reloadData];
                [self scrollToBottomAnimated:YES];
            };
            
            OSMComment * comment = [[OSMComment alloc] init];
            comment.text = [self textViewStrippedText];
            [self.note addComment:comment];
            
            [self.osmApiManager createNewComment:comment withNote:self.note success:succesBlock failure:^(NSError *error) {
                DDLogError(@"error: %@",error);
            }];
        }
        else if (buttonIndex == 1 && actionSheet.numberOfButtons > 2)
        {
            //comment & close
            [self.osmApiManager closeNote:self.note withComment:[self textViewStrippedText] success:^(id JSON) {
                self.note = [self.osmData createNoteWithJSONDictionary:JSON];
                [OPENotesDatabase saveNote:self.note completion:nil];
                [self reloadData];
                [self scrollToBottomAnimated:YES];
            } failure:^(NSError *error) {
                DDLogError(@"error: %@",error);
            }];
        }
    }else{
        if (buttonIndex == 0) {
            //comment & reopen
            [self.osmApiManager reopenNote:self.note withComment:[self textViewStrippedText] success:^(id JSON) {
                self.note = [self.osmData createNoteWithJSONDictionary:JSON];
                [OPENotesDatabase saveNote:self.note completion:nil];
                [self reloadData];
                [self scrollToBottomAnimated:YES];
            } failure:^(NSError *error) {
                DDLogError(@"error: %@",error);
            }];
        }
    }
}

-(OPEOSMAPIManager *)osmApiManager
{
    if (!_osmApiManager) {
        _osmApiManager = [[OPEOSMAPIManager alloc] init];
    }
    return _osmApiManager;
}
-(OPEOSMData *)osmData
{
    if(!_osmData)
    {
        _osmData = [[OPEOSMData alloc] init];
    }
    return _osmData;
}

@end

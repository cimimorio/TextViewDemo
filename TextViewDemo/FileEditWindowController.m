//
//  FileEditWindowController.m
//  NewFiles
//
//  Created by apple on 8/26/16.
//  Copyright © 2016 apple. All rights reserved.
//

#import "FileEditWindowController.h"

@interface FileEditWindowController ()<NSTextStorageDelegate,NSTextViewDelegate>
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (strong, nonatomic) NSMutableDictionary *docAttributes;

@property (strong) NSTextStorage *textStorage;

@property (strong) NSLayoutManager *layoutManager;

@property (strong) NSTextContainer *textContainer;

@end

@implementation FileEditWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self configUI];
}

#pragma mark -
#pragma mark 初始化UI

- (void)configUI{
	
	[self.textView setUsesRuler:YES];
	[self.textView setUsesInspectorBar:YES];
	self.textView.delegate = self;
	self.textView.editable = YES;
//	self.textContainer = [[NSTextContainer alloc] initWithContainerSize:self.textView.frame.size];
//	self.textContainer.textView = self.textView;
//	self.layoutManager = [[NSLayoutManager alloc] init];
//	[self.layoutManager addTextContainer:self.textContainer];
//	[self.textStorage addLayoutManager:self.layoutManager];
	
//	self.textStorage.delegate = self;
	
}



#pragma mark -
#pragma mark 加载数据

#pragma mark -
#pragma mark 事件
- (IBAction)insertImageBtnClicked:(id)sender {
}


- (IBAction)exportToHtmlBtnClicked:(id)sender {
	
	
	// default: Export > to HTML with styles [=embedded CSS]
	BOOL noCSS = FALSE;
	// alt: Export > to HTML (no styles) [=no CSS]
	if ([sender tag]==1) { noCSS = TRUE; }
	
	//	this part creates a folder for the exported file index.html and the objects that go with it
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *theHTMLPath = @"/Users/apple/Desktop/asds";
	int exportNumber = 0;
	NSError *theError = nil;
	
	//	we don't export images now, so this is unused
	//BOOL exportImageSuccess = YES;
	
	//	path of the HTML containing folder
	NSString *theHTMLFolderPath = [NSString stringWithFormat:@"%@%@", theHTMLPath, @" - html"];
	//	to avoid overwriting previous export, add sequential numbers to folder name
	while ([fm fileExistsAtPath:theHTMLFolderPath isDirectory:NULL] && exportNumber < 1000)
	{
		exportNumber = exportNumber + 1;
		theHTMLFolderPath = nil;
		theHTMLFolderPath = [NSString stringWithFormat:@"%@%@%i", theHTMLPath, @" - html", exportNumber];
	}
	[fm createDirectoryAtPath:theHTMLFolderPath attributes:nil];
	
	//if the folder was created, write the exported html file inside it
	if ([fm fileExistsAtPath:theHTMLFolderPath isDirectory:NULL])
	{
		NSError *outError = nil;
		
		//remember current background color
		NSColor *someColor = [[self textView] backgroundColor];
		//use non-Alternate Color mode background color during export
		[[self textView] setBackgroundColor:[NSColor whiteColor]];
		
		//	get doc-wide dictionary and set type to HTML
		NSMutableDictionary *dict = [self createDocumentAttributesDictionary];
		[dict setObject:NSHTMLTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
		
		// export with no embedded CSS (just pure HTML without styles)
		if (noCSS)
		{
			NSMutableArray *excludedElements = [NSMutableArray array];
			//strict HTML (NOT XHTML) 2.4.3 2 FEB 2010 JBH
			[excludedElements addObject:@"XML"];
			//deprecated in HTML 4.0
			[excludedElements addObjectsFromArray:[NSArray arrayWithObjects:@"APPLET", @"BASEFONT", @"CENTER", @"DIR", @"FONT", @"ISINDEX", @"MENU", @"S", @"STRIKE", @"U", nil]];
			//no embedded CSS
			[excludedElements addObject:@"STYLE"];
			[excludedElements addObject:@"SPAN"];
			[excludedElements addObject:@"Apple-converted-space"];
			[excludedElements addObject:@"Apple-converted-tab"];
			[excludedElements addObject:@"Apple-interchange-newline"];
			[dict setObject:excludedElements forKey:NSExcludedElementsDocumentAttribute];
		}
		
		//UTF=8
		[dict setObject:[NSNumber numberWithInt:NSUTF8StringEncoding] forKey:NSCharacterEncodingDocumentAttribute];
		//2 spaces for indented elements
		//todo: make number of spaces a hidden preference?
		[dict setObject:[NSNumber numberWithInt:2] forKey:NSPrefixSpacesDocumentAttribute];
		
		//	create data object for HTML
//		NSData *data = [[self textStorage] dataFromRange:NSMakeRange(0, [self.textSto rage length]) documentAttributes:dict error:&outError];
		NSData *data = [self.textView.string dataUsingEncoding:NSUTF8StringEncoding];
		
		//restore remembered color AFTER exporting data for HTML
		if (someColor)
		{
			[[self textView] setBackgroundColor:someColor];
		}
		// just in case
		else
		{
			[[self textView] setBackgroundColor:[NSColor whiteColor]];
		}
		
		//rewrote below bit 27 FEB 09 JH
		
		//	get html code as string from HTML data object
		NSString *tmpString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSMutableString *htmlString = nil;
		if (tmpString)
		{
			// make the string mutable
			htmlString = [[NSMutableString alloc] initWithCapacity:[tmpString length]];
			[htmlString setString:tmpString];
		}
		// remove extraneous path elements generated by Cocoa in HTML code for image URLs
		if (htmlString && [htmlString length]) [htmlString replaceOccurrencesOfString:@"file:///" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [htmlString length])];
		// write it to file
		if (htmlString && [htmlString length])
		{
			//	path for index.html, the exported HTML file
			NSString *theHTMLPath = [NSString stringWithFormat:@"%@%@", theHTMLFolderPath, @"/index.html"];
			NSURL *theHTMLURL = [NSURL fileURLWithPath:theHTMLPath];
			//	write index.html file
			[htmlString writeToURL:theHTMLURL atomically:YES encoding:NSUTF8StringEncoding error:&theError];
			
			/*
			 //	NOT USED!
			 //	write picture attachments to html export folder
			 //	note: the scale of these pictures in a document is not the same as the scale when placed in HTML; rather than rescaling or whatever, just export the HTML and let the user drop the image files into the HTML file's containing folder
			 
			 NSMutableAttributedString *theAttachmentString = [[NSMutableAttributedString alloc] initWithAttributedString:textStorage];
			 NSRange strRange = NSMakeRange(0, [theAttachmentString length]);
			 while (strRange.length > 0)
			 {
			 NSRange effectiveRange;
			 id attr = [theAttachmentString attribute:NSAttachmentAttributeName atIndex:strRange.location effectiveRange:&effectiveRange];
			 strRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(strRange) - NSMaxRange(effectiveRange));
			 if(attr)
			 {
			 NSTextAttachment *attachment = (NSTextAttachment *)attr;
			 NSFileWrapper *fileWrapper = [attachment fileWrapper];
			 NSString *fileWrapperPath = [fileWrapper filename];
			 NSString *pictureExportPath = [NSString stringWithFormat:@"%@%@%@", theHTMLFolderPath, @"/", fileWrapperPath];
			 //NSLog(pictureExportPath);
			 BOOL success = YES;
			 success = [fileWrapper writeToFile:pictureExportPath atomically:YES updateFilenames:YES];
			 if (success==NO) exportImageSuccess = NO;
			 attachment = nil;
			 fileWrapper = nil;
			 fileWrapperPath = nil;
			 pictureExportPath = nil;
			 }
			 }
			 [theAttachmentString release];
			 */
		}
	}
	//there was an error in creating the export folder
	else
	{
		NSBeep();
	}
	//	error alert dialog
	if (![fm fileExistsAtPath:theHTMLFolderPath isDirectory:NULL] || theError)
	{
		NSString *anError = [theError localizedDescription];
		NSString *alertTitle = nil;
		if (theError)
		{
			alertTitle =  [NSString stringWithFormat:NSLocalizedString(@"Export to HTML failed: %@", @"alert title: Export to HTML failed: (localized reason for failure automatically inserted at runtime)"), anError];
		}
		else
		{
			alertTitle = NSLocalizedString(@"Export to HTML failed.", @"Export to HTML failed.");
		}
		[[NSAlert alertWithMessageText:alertTitle
						 defaultButton:NSLocalizedString(@"OK", @"OK")
					   alternateButton:nil
						   otherButton:nil
			 informativeTextWithFormat:NSLocalizedString(@"A problem prevented the document from being exported to HTML format.", @"alert text: A problem prevented the document from being exported to HTML format.")] runModal];
		alertTitle = nil;
	}
	
	/*
	 else if (theError==nil && exportImageSuccess == NO)
	 {
	 [[NSAlert alertWithMessageText:NSLocalizedString(@"There was a problem exporting image files.", @"Title of alert indicating that there was a problem exporting image files.")
	 defaultButton:NSLocalizedString(@"OK", @"OK")
	 alternateButton:nil
	 otherButton:nil
	 informativeTextWithFormat:NSLocalizedString(@"You can manually drag image files from the Finder into the revealed HTML file's folder to solve the problem.", @"Text of alert indicating you can manually drag image files from the Finder into the revealed HTML file's folder to solve the problem.")] runModal];
	 }
	 */
	
	else
	{
		//	show exported file in Finder for the user
		[[NSWorkspace sharedWorkspace] selectFile:theHTMLFolderPath inFileViewerRootedAtPath:nil];
	}

	
}

- (IBAction)txt:(id)sender {
	
	
}
- (IBAction)pdf:(id)sender {
	
	
}


- (IBAction)rtf:(id)sender {
}

#pragma mark -
#pragma mark 数据请求

#pragma mark -
#pragma mark 代理

#pragma mark -- textStorageDelegate

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta{

}

- (void)textStorage:(NSTextStorage *)textStorage willProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta{
	
}

#pragma mark -
#pragma mark 业务逻辑


- (NSMutableDictionary *) createDocumentAttributesDictionary
{
	//	view scale
	float zoomValue = 100.0;
	
	//	open in layout view? layout view = 1; continuous view = 0
	//	historical note: formerly, we also did viewmode 2 (fitWidth) and 3 (fitPage)
	//	but Word opens these in outline mode; so we handle those viewmodes now with keywords.
	int showLayout = 1;
	
	//	create a 'keyword' for saving the cursor location
	//	TODO: shouldn't add these kinds of keywords in for HTML export
	int cursorLoc = [self.textView selectedRange].location;
	NSString *cursorLocation = nil;
	if (cursorLoc > 0) { cursorLocation = [NSString stringWithFormat:@"cursorLocation=%i", cursorLoc]; }
	
	//	create a 'keyword' for saving the Fit to Width/Fit to Page if needed  // 12 MAY 08 JH
	NSString *fitViewType = nil;
//	if ([theScrollView isFitWidth]) { fitViewType = @"fitsPagesWidth=1"; }
//	if ([theScrollView isFitPage]) { fitViewType = @"fitsWholePages=1"; }
	fitViewType = @"fitsPagesWidth=1";
	fitViewType = @"fitsWholePages=1";
	//	create a 'keyword' for saving key that tells whether to do automaticBackup at close
	NSString *automaticBackup = nil;
//	if ([self shouldCreateDatedBackup]) { automaticBackup = @"automaticBackup=1"; }
	automaticBackup = @"automaticBackup=1";
	//	create a 'keyword' for saving alt colors if shouldUseAltTextColors AND not using them only because of full screen mode
	NSString *alternateColors = nil;
	
//	if ([self shouldUseAltTextColors] && ![self shouldRestoreAltTextColors]
//		&& !([self fullScreen] && [self shouldUseAltTextColors] && ![self shouldUseAltTextColorsInNonFullScreen]))
//	{
//		alternateColors = @"alternateColors=1";
//	}
	alternateColors = @"alternateColors=1";
	//	create a 'keyword' to inform Bean that the text is supposed to be zero length (but one character was saved to preserve attributes)
	//	zeroLengthText1 means delete placeholder character upon opening document
	NSString *zeroLengthText = nil;
//	if ([self textLengthIsZero]) { zeroLengthText = @"zeroLengthText=1"; }
	
	//	create a 'keyword' for saving whether to do Autosave
	NSString *autosaveInterval = nil;
//	if ([self doAutosave])
//	{
//		if ([self autosaveTime])
//		{
//			autosaveInterval = [NSString stringWithFormat:@"autosaveInterval=%i", [self autosaveTime]];
//		}
//	}
	
	//save header/footer settings when Format > Header/Footer... > Lock settings for header/footer is selected
	NSString *headerFooter = nil;
//	if ([self headerFooterSetting] > 0)
//	{
//		headerFooter = [NSString stringWithFormat:@"headerFooter=%istyle=%istartPage=%i", [self headerFooterSetting] - 1, [self headerFooterStyle], [self headerFooterStartPage]];
//	}
	
	//columns
//	NSString *columns = nil;
//	if ([self numberColumns] > 1)
//	{
//		columns = [NSString stringWithFormat:@"columns=%igutter=%i", [self numberColumns], [self columnsGutter]];
//	}
	
	//	keywords array holds keywords from docAttributes dictionary plus our special document attribute keywords
//	NSMutableArray *keywords = [NSMutableArray arrayWithCapacity:0];
//	NSArray *anArray = [[self docAttributes] objectForKey:NSKeywordsDocumentAttribute];
//	if ([anArray count])
//		[keywords addObjectsFromArray:[NSArray arrayWithArray:anArray]];
//	//	add special Bean keywords
//	if (cursorLocation) { [keywords addObject:cursorLocation]; }
//	if (automaticBackup) { [keywords addObject:automaticBackup]; }
//	if (autosaveInterval) { [keywords addObject:autosaveInterval]; }
//	if (zeroLengthText) { [keywords addObject:zeroLengthText]; }
//	if (alternateColors) { [keywords addObject:alternateColors]; }
//	if (fitViewType) { [keywords addObject:fitViewType]; } // 12 MAY 08 JH
//	if (headerFooter) { [keywords addObject:headerFooter]; } //18 NOV 08 JH
//	if (columns) { [keywords addObject:columns]; } //18 NOV 08 JH
//	
//	//don't save 'alt colors' background color as document background color
//	NSColor *backgroundColor;
//	
//	if ([self shouldUseAltTextColors] && [[self firstTextView] allowsDocumentBackgroundColorChange])
//	{
//		backgroundColor = [self theBackgroundColor];
//	}
//	else if ([self shouldUseAltTextColors] && ![[self firstTextView] allowsDocumentBackgroundColorChange])
//	{
//		backgroundColor = [NSColor whiteColor];
//	}
//	else
//	{
//		backgroundColor = [[self firstTextView] backgroundColor];
//	}
	
	//	create document attributes dictionary
	//	NOTE: for some reason, NSKeywordDocumentAttribute must precede the 'string' property attrs or it is not saved
	//	NSViewSize is window size
	//	we ceil NSViewZoomDocAttr so saved value = slider value
	NSMutableDictionary *dict;
	dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSValue valueWithSize:self.textView.frame.size], NSViewSizeDocumentAttribute,
			[NSNumber numberWithInt:showLayout], NSViewModeDocumentAttribute,
			[NSValue valueWithSize:self.textView.frame.size], NSPaperSizeDocumentAttribute,
			[NSNumber numberWithFloat:ceil(zoomValue * 100)], NSViewZoomDocumentAttribute,
			[NSNumber numberWithInt: 0], NSReadOnlyDocumentAttribute,
			[NSNumber numberWithFloat:[[self printInfo] leftMargin]], NSLeftMarginDocumentAttribute,
			[NSNumber numberWithFloat:[[self printInfo] rightMargin]], NSRightMarginDocumentAttribute,
			[NSNumber numberWithFloat:[[self printInfo] bottomMargin]], NSBottomMarginDocumentAttribute,
			[NSNumber numberWithFloat:[[self printInfo] topMargin]], NSTopMarginDocumentAttribute,
			[NSColor whiteColor], NSBackgroundColorDocumentAttribute,
			@"Love", NSKeywordsDocumentAttribute,
			[[self docAttributes] valueForKey:NSAuthorDocumentAttribute], NSAuthorDocumentAttribute,
			[[self docAttributes] valueForKey:NSCompanyDocumentAttribute], NSCompanyDocumentAttribute,
			[[self docAttributes] valueForKey:NSCopyrightDocumentAttribute], NSCopyrightDocumentAttribute,
			[[self docAttributes] valueForKey:NSTitleDocumentAttribute], NSTitleDocumentAttribute,
			[[self docAttributes] valueForKey:NSSubjectDocumentAttribute], NSSubjectDocumentAttribute,
			[[self docAttributes] valueForKey:NSCommentDocumentAttribute], NSCommentDocumentAttribute,
			[[self docAttributes] valueForKey:NSEditorDocumentAttribute], NSEditorDocumentAttribute,
			nil];
	
	return dict;
}

- (NSPrintInfo *)printInfo
{
//	PageView *pageView = [theScrollView documentView];
	NSPrintInfo *printInfo;
	if (printInfo == nil)
	{
//		[self setPrintInfo:[NSPrintInfo sharedPrintInfo]];
//		[pageView setPrintInfo:[NSPrintInfo sharedPrintInfo]];
		[printInfo setHorizontalPagination:NSFitPagination];
		[printInfo setHorizontallyCentered:NO];
		[printInfo setVerticallyCentered:NO];
	}
	return printInfo;
}

#pragma mark -
#pragma mark 通知注册和销毁






@end

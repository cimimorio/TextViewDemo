//
//  AppDelegate.m
//  TextViewDemo
//
//  Created by apple on 8/26/16.
//  Copyright © 2016 apple. All rights reserved.
//

#import "AppDelegate.h"
#import "FileEditWindowController.h"
@interface AppDelegate ()

@property (strong) FileEditWindowController *windowController;

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	
	self.windowController = [[FileEditWindowController alloc] initWithWindowNibName:@"FileEditWindowController"];
	[self.windowController.window makeMainWindow];
	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end

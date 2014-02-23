//
//  BPApplication.m
//  TipTyper
//
//  Created by Bruno Philipe on 10/14/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPApplication.h"
#import "BPDocumentWindow.h"

typedef enum {
	BP_DEFAULTS_FONT =			(1<<1),
	BP_DEFAULTS_TXTCOLOR =		(1<<2),
	BP_DEFAULTS_BGCOLOR =		(1<<3),
	BP_DEFAULTS_SHOWLINES =		(1<<4),
	BP_DEFAULTS_SHOWSTATUS =	(1<<5)
} BP_DEFAULT_TYPES;

@implementation BPApplication
{
	NSWindowController *prefWindowController;
	NSWindow *prefWindow;
	BP_DEFAULT_TYPES changedAttributes;
}

- (void)setKeyDocument:(BPDocument *)keyDocument
{
	self.keyDocument_showingLines = [keyDocument.displayWindow isDisplayingLines];
	self.keyDocument_showingInfo = [keyDocument.displayWindow isDisplayingInfo];
//	self.keyDocument_isLinkedToFile;
}

- (IBAction)openWebsite:(id)sender
{
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	[ws openURL:[NSURL URLWithString:@"http://www.brunophilipe.com/software/tiptyper"]];
}

- (IBAction)showPreferences:(id)sender
{
	if (!prefWindow)
	{
		prefWindowController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
		prefWindow = prefWindowController.window;

		[self configurePrefWindow];

		[prefWindow setAnimationBehavior:NSWindowAnimationBehaviorDocumentWindow];
	}
	[prefWindowController performSelector:@selector(showWindow:) withObject:self afterDelay:0.2];
}

#pragma mark - Preferences Window

- (void)configurePrefWindow
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	id aux;

	if ((aux = [defaults objectForKey:kBP_DEFAULT_BGCOLOR])) {
		[self setColor_bg:[NSKeyedUnarchiver unarchiveObjectWithData:aux]];
	} else {
		[self setColor_bg:kBP_TIPTYPER_BGCOLOR];
	}

	if ((aux = [defaults objectForKey:kBP_DEFAULT_TXTCOLOR])) {
		[self setColor_text:[NSKeyedUnarchiver unarchiveObjectWithData:aux]];
	} else {
		[self setColor_text:kBP_TIPTYPER_TXTCOLOR];
	}

	if ((aux = [defaults objectForKey:kBP_DEFAULT_FONT])) {
		[self setCustomFont:[NSKeyedUnarchiver unarchiveObjectWithData:aux]];
	} else {
		[self setCustomFont:kBP_TIPTYPER_FONT];
	}

	if ((aux = [defaults objectForKey:kBP_DEFAULT_SHOWLINES])) {
		[self.checkbox_showLines setState:([(NSNumber*)aux boolValue] ? NSOnState : NSOffState)];
	} else {
		[self.checkbox_showLines setState:NSOnState];
	}

	if ((aux = [defaults objectForKey:kBP_DEFAULT_SHOWSTATUS])) {
		[self.checkbox_showStatus setState:([(NSNumber*)aux boolValue] ? NSOnState : NSOffState)];
	} else {
		[self.checkbox_showStatus setState:NSOnState];
	}

	[self.textView_example setTextColor:self.color_text];
	[self.textView_example setBackgroundColor:self.color_bg];

	[[prefWindow.contentView viewWithTag:-3] performSelector:@selector(setColor:) withObject:self.color_text];
	[[prefWindow.contentView viewWithTag:-4] performSelector:@selector(setColor:) withObject:self.color_bg];
}

- (void)changeFont:(id)sender
{
	NSFontManager *fm = sender;

	[self setCustomFont:[fm convertFont:self.currentFont]];

	changedAttributes |= BP_DEFAULTS_FONT;
}

- (void)setCustomFont:(NSFont *)font
{
	self.currentFont = font;

	[self.field_currentFont setFont:[NSFont fontWithName:self.currentFont.fontName size:12]];
	[self.field_currentFont setStringValue:[NSString stringWithFormat:@"%@ %.0fpt",self.currentFont.displayName,self.currentFont.pointSize]];

	[self.textView_example setFont:self.currentFont];
}

#pragma mark - IBActions

- (IBAction)action_changeFont:(id)sender {
	[[NSFontManager sharedFontManager] setDelegate:self];

	NSFontPanel *panel = [NSFontPanel sharedFontPanel];
	[panel makeKeyAndOrderFront:self];
}

- (IBAction)action_revertDefaults:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults setObject:nil forKey:kBP_DEFAULT_BGCOLOR];
	[defaults setObject:nil forKey:kBP_DEFAULT_TXTCOLOR];
	[defaults setObject:nil forKey:kBP_DEFAULT_FONT];
	[defaults setObject:nil forKey:kBP_DEFAULT_SHOWSTATUS];
	[defaults setObject:nil forKey:kBP_DEFAULT_SHOWLINES];

	[defaults synchronize];

	changedAttributes = 0;

	[self configurePrefWindow];

	[[NSNotificationCenter defaultCenter] postNotificationName:kBP_SHOULD_RELOAD_STYLE object:self];
}

- (IBAction)action_controlChanged:(id)sender {
	switch ([(NSControl *)sender tag]) {
		case -1: //Show lines
			self.pref_default_lines = [(NSButton*)sender state] == NSOnState;
			changedAttributes |= BP_DEFAULTS_SHOWLINES;
			break;

		case -2: //Show status
			self.pref_default_status = [(NSButton*)sender state] == NSOnState;
			changedAttributes |= BP_DEFAULTS_SHOWSTATUS;
			break;

		case -3: //Font color
			self.color_text = [(NSColorWell *)sender color];
			[self.textView_example setTextColor:self.color_text];
			changedAttributes |= BP_DEFAULTS_TXTCOLOR;
			break;

		case -4: //BG color
			self.color_bg = [(NSColorWell *)sender color];
			[self.textView_example setBackgroundColor:self.color_bg];
			changedAttributes |= BP_DEFAULTS_BGCOLOR;
			break;
	}
}

- (IBAction)action_applyChanges:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if (changedAttributes & BP_DEFAULTS_FONT) {
		[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.currentFont] forKey:kBP_DEFAULT_FONT];
	}
	if (changedAttributes & BP_DEFAULTS_BGCOLOR) {
		[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.color_bg] forKey:kBP_DEFAULT_BGCOLOR];
	}
	if (changedAttributes & BP_DEFAULTS_TXTCOLOR) {
		[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.color_text] forKey:kBP_DEFAULT_TXTCOLOR];
	}
	if (changedAttributes & BP_DEFAULTS_SHOWLINES) {
		[defaults setObject:[NSNumber numberWithBool:([self.checkbox_showLines state] == NSOnState)] forKey:kBP_DEFAULT_SHOWLINES];
	}
	if (changedAttributes & BP_DEFAULTS_SHOWSTATUS) {
		[defaults setObject:[NSNumber numberWithBool:([self.checkbox_showStatus state] == NSOnState)] forKey:kBP_DEFAULT_SHOWSTATUS];
	}

	changedAttributes = 0;

	[defaults synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:kBP_SHOULD_RELOAD_STYLE object:self];
}

@end
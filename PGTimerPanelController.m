/* Copyright © 2007-2008, The Sequential Project
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the the Sequential Project nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE SEQUENTIAL PROJECT ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE SEQUENTIAL PROJECT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "PGTimerPanelController.h"

// Models
#import "PGPrefObject.h"
#import "PGDocument.h"

// Views
#import "PGTimerButton.h"

// Controllers
#import "PGDisplayController.h"

// Other
#import "PGNonretainedObjectProxy.h"

// Categories
#import "NSObjectAdditions.h"
#import "NSNumberAdditions.h"

@interface PGTimerPanelController (Private)

- (PGPrefObject *)_currentPrefObject;
- (void)_update;
- (void)_updateOnTimer:(NSTimer *)timer;

@end

@implementation PGTimerPanelController

#pragma mark Instance Methods

- (IBAction)toggleTimer:(id)sender
{
	[[self displayController] setTimerRunning:![[self displayController] isTimerRunning]];
}
- (IBAction)changeTimerInterval:(id)sender
{
	NSTimeInterval const interval = round([sender doubleValue]);
	[[self _currentPrefObject] setTimerInterval:interval];
	[self _updateOnTimer:nil];
}

#pragma mark -

- (void)displayControllerTimerDidChange:(NSNotification *)aNotif
{
	[self _update];
}

#pragma mark Private Protocol

- (PGPrefObject *)_currentPrefObject
{
	PGDocument *const doc = [[self displayController] activeDocument];
	return doc ? doc : [PGPrefObject globalPrefObject];
}
- (void)_update
{
	PGDisplayController *const d = [self displayController];
	BOOL const run = [d isTimerRunning];
	if(![self isShown] || !run) {
		[_updateTimer invalidate];
		[_updateTimer release];
		_updateTimer = nil;
	} else if(!_updateTimer) {
		_updateTimer = [[NSTimer timerWithTimeInterval:1.0 / 24.0 target:[self PG_nonretainedObjectProxy] selector:@selector(_updateOnTimer:) userInfo:nil repeats:YES] retain];
		[[NSRunLoop currentRunLoop] addTimer:_updateTimer forMode:PGCommonRunLoopsMode];
	}
	[timerButton setEnabled:!!d];
	[timerButton setIconType:run ? AEStopIcon : AEPlayIcon];
	[self _updateOnTimer:nil];
}
- (void)_updateOnTimer:(NSTimer *)timer
{
	NSTimeInterval const interval = [[self _currentPrefObject] timerInterval];
	BOOL const running = [[self displayController] isTimerRunning];
	NSTimeInterval timeRemaining = interval;
	if(running) {
		NSDate *const fireDate = [[self displayController] nextTimerFireDate];
		timeRemaining = MAX(0.0f, fireDate ? [fireDate timeIntervalSinceNow] : 0.0f);
	}
	[timerButton setProgress:(running ? (interval - timeRemaining) / interval : 0)];
	[remainingField setStringValue:[NSString localizedStringWithFormat:NSLocalizedString(@"%.1f seconds", @"Display string for timer intervals. %.1f is replaced with the remaining seconds and tenths of seconds."), timeRemaining]];
	if(!timer) {
		[totalField setStringValue:[NSString localizedStringWithFormat:NSLocalizedString(@"%.1f seconds", @"Display string for timer intervals. %.1f is replaced with the remaining seconds and tenths of seconds."), interval]];
		[intervalSlider setDoubleValue:interval];
		[intervalSlider setEnabled:!![self displayController]];
	}
}

#pragma mark PGFloatingPanelController

- (void)setShown:(BOOL)flag
{
	[super setShown:flag];
	[self _update];
}
- (BOOL)setDisplayController:(PGDisplayController *)controller
{
	PGDisplayController *const oldController = [self displayController];
	if(![super setDisplayController:controller]) return NO;
	[oldController AE_removeObserver:self name:PGDisplayControllerTimerDidChangeNotification];
	PGDisplayController *const newController = [self displayController];
	[newController AE_addObserver:self selector:@selector(displayControllerTimerDidChange:) name:PGDisplayControllerTimerDidChangeNotification];
	[self _update];
	return YES;
}
- (NSString *)nibName
{
	return @"PGTimer";
}

#pragma mark NSWindowController

- (void)windowDidLoad
{
	[super windowDidLoad];
	[self _updateOnTimer:nil];
}

#pragma mark NSObject

- (id)init
{
	return [self initWithWindowNibName:@"PGTimer"];
}
- (void)dealloc
{
	[self AE_removeObserver];
	[_updateTimer invalidate];
	[_updateTimer release];
	[super dealloc];
}

@end

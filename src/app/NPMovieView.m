/* ***** BEGIN LICENSE BLOCK *****
* Version: MPL 1.1/GPL 2.0/LGPL 2.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* The Original Code is NicePlayer.
*
* The Initial Developer of the Original Code is
* James Tuley & Robert Chin.
* Portions created by the Initial Developer are Copyright (C) 2004-2005
* the Initial Developer. All Rights Reserved.
*
* Contributor(s):
*           Robert Chin <robert@osiris.laya.com> (NicePlayer Author)
*           James Tuley <jay+nicesource@tuley.name> (NicePlayer Author)
*
* Alternatively, the contents of this file may be used under the terms of
* either the GNU General Public License Version 2 or later (the "GPL"), or
* the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
* in which case the provisions of the GPL or the LGPL are applicable instead
* of those above. If you wish to allow use of your version of this file only
* under the terms of either the GPL or the LGPL, and not to allow others to
* use your version of this file under the terms of the MPL, indicate your
* decision by deleting the provisions above and replace them with the notice
* and other provisions required by the GPL or the LGPL. If you do not delete
* the provisions above, a recipient may use your version of this file under
* the terms of any one of the MPL, the GPL or the LGPL.
*
* ***** END LICENSE BLOCK ***** */

#import "NPMovieView.h"
#import "ControlPlay.h"
#import "NiceWindow.h"
#import "NiceDocument.h"

#define SCRUB_STEP_DURATION 5

@implementation NPMovieView

-(NiceDocument*)niceDocument
{
    return [[[self window] windowController] document];
}

-(NiceWindow*)niceWindow
{
    return (NiceWindow*) [self window];
}

-(id)initWithFrame:(NSRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        [self setAutoresizesSubviews:YES];
    }
    return self;
}

-(void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(rebuildTrackingRects)
						     name:NSViewFrameDidChangeNotification
						   object:self];	
	trackingRect = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

-(void)rebuildTrackingRects
{
	[self viewWillMoveToWindow:[self window]];
}

-(void)viewWillMoveToWindow:(NSWindow *)window
{
	if([self window])
		[self removeTrackingRect:trackingRect];
	if(window)
		trackingRect = [self addTrackingRect:[self bounds] owner:window userData:nil assumeInside:NO];
}

-(void)close
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [qtview setMovie:nil];
    [qtview removeFromSuperviewWithoutNeedingDisplay];
    qtview = nil;
    movie = nil;
}

-(void)dealloc
{
	[self close];
    if(mouseEntered)
		[self mouseExited:nil];
    [super dealloc];
}

-(void)openMovie:aMovie
{
    qtview = [[QTMovieView alloc] initWithFrame:[self bounds]];
    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [qtview setFillColor:[NSColor blackColor]];
    [qtview setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [qtview setControllerVisible:NO];
    [qtview setEditable:NO];
    [qtview setPreservesAspectRatio:NO];
    [qtview setMovie:aMovie];
    [self addSubview:qtview];

    movie = aMovie;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
}

-(NSView *)hitTest:(NSPoint)aPoint
{
    if(NSMouseInRect(aPoint, [self frame], NO))
        return self;
    return nil;
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

#pragma mark -
#pragma mark Widgets

-(IBAction)scrub:(id)sender
{
    [[self niceDocument] setMovieTimeByFraction:[sender doubleValue]];
    [[self niceWindow] updateByTime:sender];
}

#pragma mark -
#pragma mark Keyboard Events

-(void)keyDown:(NSEvent *)anEvent
{
    if(([anEvent modifierFlags] & NSShiftKeyMask)) return;
    
    switch([[anEvent characters] characterAtIndex:0]){
		case ' ':
			if(![anEvent isARepeat]) [[self niceDocument] togglePlayingMovie];
			break;
		case NSRightArrowFunctionKey:
            if(![anEvent isARepeat]) [[self niceDocument] startStepping];
            [[self niceDocument] stepBy:SCRUB_STEP_DURATION];
			break;
		case NSLeftArrowFunctionKey:
			if([anEvent modifierFlags] & NSCommandKeyMask){
                [[self niceDocument] setCurrentMovieTime:0];
				break;
			}
            if(![anEvent isARepeat]) [[self niceDocument] startStepping];
            [[self niceDocument] stepBy:-SCRUB_STEP_DURATION];
			break;
		case NSUpArrowFunctionKey:
			[[self niceDocument] incrementVolume];
			[[self niceWindow] showVolumeOverlay];
			break;
		case NSDownArrowFunctionKey:
			[[self niceDocument] decrementVolume];
			[[self niceWindow] showVolumeOverlay];
			break;
		case 0x1B:
			[[self niceWindow] unFullScreen];
			break;
		default:
			[super keyDown:anEvent];
    }
}

-(void)keyUp:(NSEvent*)anEvent
{
	if(([anEvent modifierFlags] & NSShiftKeyMask)) return;

	switch([[anEvent characters] characterAtIndex:0]){
		case ' ':
			break;
		case NSRightArrowFunctionKey:
			[[self niceDocument] endStepping];
			break;
		case NSLeftArrowFunctionKey:
			[[self niceDocument] endStepping];
			break;
		default:
			[super keyUp:anEvent];
    }
}

#pragma mark -
#pragma mark Mouse Events

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)mouseDown:(NSEvent *)anEvent
{
    [[self niceWindow] mouseDown:anEvent];
}

- (void)mouseUp:(NSEvent *)anEvent
{
	[[self niceWindow] mouseUp:anEvent];
}

- (void)mouseMoved:(NSEvent *)anEvent
{
	[[self niceWindow] mouseMoved:anEvent];
}

-(void)mouseDragged:(NSEvent *)anEvent
{
    [[self niceWindow] mouseDragged:anEvent];
}

#pragma mark -
#pragma mark Pluggables

-(void)drawMovieFrame
{
    [qtview setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [NSApp mouseEntered:theEvent];
    mouseEntered = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [NSApp mouseExited:theEvent];
    mouseEntered = NO;
}

@end

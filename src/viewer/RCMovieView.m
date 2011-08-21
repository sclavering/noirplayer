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

#import "RCMovieView.h"

@implementation RCMovieView

+(RCMovieView *)makeWithURL:(NSURL *)url
{
    // The frame is reset to something sane later
    RCMovieView* view = [[[RCMovieView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)] autorelease];
    return view && [view openURL:url] ? view : nil;
}

-(QTMovie*)qtmovie { return film; }
-(QTMovieView*)qtview { return qtView; }

/* Forward all drag events to the window itself. */
-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [[self _windowDrag] draggingEntered:sender];
}

-(NSDragOperation)draggingUpdated:(id)sender
{
	return [[self _windowDrag] draggingUpdated:sender];
}

-(BOOL)prepareForDragOperation:(id)sender
{
	return [[self _windowDrag] prepareForDragOperation:sender];
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [[self _windowDrag] performDragOperation:sender];
}

-(void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[[self _windowDrag] concludeDragOperation:sender];
}

-(id<NSDraggingDestination>)_windowDrag
{
    // We know our window is a NiceWindow, which implements the protocol
    return (id<NSDraggingDestination>) [self window];
}

-(BOOL)openURL:(NSURL *)url
{
    [film release];
    film = [[QTMovie movieWithURL:url error:nil] retain];
    if(!film) return NO;
    [qtView setMovie:film];
    return YES;
}

-(id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame])){
        qtView = [[QTMovieView alloc] initWithFrame:frame];
        [self addSubview:qtView];
        [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [qtView setFillColor:[NSColor blackColor]];
        [qtView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [qtView setControllerVisible:NO];
        [qtView setEditable:NO];
        [qtView setPreservesAspectRatio:NO];
    }
    return self;
}

-(void)dealloc
{
	[self close];
    [super dealloc];
}

-(void)close
{
	[film release];
	film =nil;
	[qtView setMovie:nil];
	[qtView release];
	[qtView removeFromSuperviewWithoutNeedingDisplay];
	qtView = nil;
}

-(void)drawMovieFrame
{
    [qtView setNeedsDisplay:YES];
}

-(NSSize)naturalSize
{
    return [[film attributeForKey: QTMovieNaturalSizeAttribute] sizeValue];
}

- (void)drawRect:(NSRect)aRect
{
    [qtView drawRect:aRect];
}

#pragma mark -
#pragma mark Controls

-(BOOL)isPlaying
{
    return ([film rate] != 0.0);
}

-(void)start
{
    [film play];
}

-(void)stop
{
    [film stop];
}

@end

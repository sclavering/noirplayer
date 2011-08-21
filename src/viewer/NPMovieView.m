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
#import "RCMovieView.h"

#define SCRUB_STEP_DURATION 5

@interface NPMovieView(private)
-(NSNumber*)_percentLoaded;
@end

@implementation NPMovieView

-(id)initWithFrame:(NSRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        trueMovieView = nil;
        contextMenu = [[NSMenu alloc] initWithTitle:@"NicePlayer"];
        wasPlaying = NO;
        [self addSubview:trueMovieView];
        [self setAutoresizesSubviews:YES];
		title = nil;
		internalVolume = 1.0;
    }
    return self;
}

-(void)awakeFromNib
{
	[self registerForDraggedTypes:[(NiceWindow *)[self window] acceptableDragTypes]];
	[trueMovieView registerForDraggedTypes:[(NiceWindow *)[self window] acceptableDragTypes]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(rebuildMenu)
												 name:@"RebuildMenu"
											   object:nil];	
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
	[self unregisterDraggedTypes];
}

-(void)dealloc
{
	[self close];
    if(mouseEntered)
		[self mouseExited:nil];
    [title release];
    [super dealloc];
}

-(void)openURL:(NSURL *)url withMovieView:view
{
    if(title) [title release];
    title = [[[[url path] lastPathComponent] stringByDeletingPathExtension] retain];

    trueMovieView = view;
    [view setFrame: [self bounds]];

    [self addSubview:trueMovieView];

    [trueMovieView setVolume:internalVolume];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
    [trueMovieView registerForDraggedTypes:[(NiceWindow *)[self window] acceptableDragTypes]];
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
#pragma mark Controls

-(void)start
{
    wasPlaying = YES;
    [trueMovieView start];
    [[((NiceWindow *)[self window]) playButton] changeToProperButton:[trueMovieView isPlaying]];
}

-(void)stop
{
    wasPlaying = NO;
    
    [trueMovieView stop];
    [[((NiceWindow *)[self window]) playButton] changeToProperButton:[trueMovieView isPlaying]];
}

-(void)ffStart
{
    [trueMovieView ffStart:SCRUB_STEP_DURATION];
    [((NiceWindow *)[self window]) updateByTime:nil];
}

-(void)ffDo
{
    [self ffDo:SCRUB_STEP_DURATION];
}

-(void)ffDo:(int)aSeconds
{
    [trueMovieView ffDo:aSeconds];
    [((NiceWindow *)[self window]) updateByTime:nil];
}

-(void)ffEnd
{
    [trueMovieView ffEnd];
    [((NiceWindow *)[self window]) updateByTime:nil];
}

-(void)rrStart
{
    [trueMovieView rrStart:SCRUB_STEP_DURATION];
    [((NiceWindow *)[self window]) updateByTime:nil];
}

-(void)rrDo
{
    [self rrDo:SCRUB_STEP_DURATION];
}

-(void)rrDo:(int)aSeconds{
    [trueMovieView rrDo:aSeconds];
    [((NiceWindow *)[self window]) updateByTime:nil];
}

-(void)rrEnd
{
    [trueMovieView rrEnd];
    [((NiceWindow *)[self window]) updateByTime:nil];
}

-(void)toggleMute
{
    [trueMovieView setMuted:![trueMovieView muted]];
    [((NiceWindow *)[self window]) updateVolume];
}

-(void)incrementVolume
{
	[self setMuted:NO];
	[self setVolume:[self volume]+.1];
	[((NiceWindow *)[self window]) updateVolume];
}

-(void)decrementVolume
{
	[self setMuted:NO];
	[self setVolume:[self volume]-.1];
	[((NiceWindow *)[self window]) updateVolume];
}

#pragma mark -
#pragma mark Widgets

-(IBAction)scrub:(id)sender
{
	[trueMovieView setCurrentMovieTime:([trueMovieView totalTime] * [sender doubleValue])];
    [((NiceWindow *)[self window]) updateByTime:sender];
}

-(double)scrubLocation:(id)sender
{
	return (double)[trueMovieView currentMovieTime] / (double)[trueMovieView totalTime];
}

-(BOOL)isPlaying
{
	return [trueMovieView isPlaying];
}

-(BOOL)wasPlaying
{
    return wasPlaying;
}

#pragma mark -
#pragma mark Keyboard Events

-(void)keyDown:(NSEvent *)anEvent
{
    if(([anEvent modifierFlags] & NSShiftKeyMask)){
		/* Pass down shift flagged keys to trueMovieView */
		[trueMovieView keyDown:anEvent];
		return;
    }
    
    switch([[anEvent characters] characterAtIndex:0]){
		case ' ':
			if(![anEvent isARepeat]){
				[[((NiceWindow *)[self window]) playButton] togglePlaying];
			}
			break;
		case NSRightArrowFunctionKey:
			if(![anEvent isARepeat])
				[self ffStart];
			else
				[self ffDo];
			break;
		case NSLeftArrowFunctionKey:
			if([anEvent modifierFlags] & NSCommandKeyMask){
                [trueMovieView setCurrentMovieTime:0];
				break;
			}
			if(![anEvent isARepeat])
				[self rrStart];
			else
				[self rrDo];
			break;
		case NSUpArrowFunctionKey:
			[self incrementVolume];
			[self showOverLayVolume];
			break;
		case NSDownArrowFunctionKey:
			[self decrementVolume];
			[self showOverLayVolume];
			break;
		case NSDeleteFunctionKey:
			[self toggleMute];
			[self showOverLayVolume];
			break;
		case 0x1B:
			[((NiceWindow *)[self window]) unFullScreen];
			break;
		default:
			[super keyDown:anEvent];
    }
}

-(void)keyUp:(NSEvent*)anEvent
{
	if(([anEvent modifierFlags] & NSShiftKeyMask)){
		/* Pass down shift flagged keys to trueMovieView */
		[trueMovieView keyUp:anEvent];
		return;
    }
	
	switch([[anEvent characters] characterAtIndex:0]){
		case ' ':
			[self smartHideMouseOverOverlays];
			break;
		case NSRightArrowFunctionKey:
			[self ffEnd];
			[self smartHideMouseOverOverlays];
			break;
		case NSLeftArrowFunctionKey:
			[self rrEnd];
			[self smartHideMouseOverOverlays];
			break;
		case NSUpArrowFunctionKey: case NSDownArrowFunctionKey:
			[self timedHideVolumeOverlay];
 			break;
		default:
			[super keyUp:anEvent];
    }
}

-(void)showOverLayVolume
{
	[NSObject cancelPreviousPerformRequestsWithTarget:[self window] selector:@selector(hideOverLayVolume:) object:nil];
	[((NiceWindow *)[self window])automaticShowOverLayVolume];
	[self timedHideVolumeOverlay];
}

-(void)smartHideMouseOverOverlays
{
	/* Simulate and distribute a mouse moved event for the window so that the proper menu stuff gets displayed
	if we're in a zone that's between gui buttons. */
	NSEvent *newEvent = [NSEvent mouseEventWithType:NSMouseMoved
										   location:[((NiceWindow *)[self window]) convertScreenToBase:[NSEvent mouseLocation]]
									  modifierFlags:0
										  timestamp:0
									   windowNumber:0
											context:nil
										eventNumber:0
										 clickCount:0
										   pressure:1.0];
	[((NiceWindow *)[self window]) mouseMoved:newEvent];
}

-(void)timedHideVolumeOverlay
{
	[[self window] performSelector:@selector(hideOverLayVolume:) withObject:nil afterDelay:1.0];
}

#pragma mark -
#pragma mark Mouse Events

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)mouseDown:(NSEvent *)anEvent
{
	   if([anEvent type] == NSLeftMouseDown){
			  if(([anEvent modifierFlags] & NSControlKeyMask) == NSControlKeyMask){ /* This is a control click. */
				  [self rightMouseDown:anEvent];
				  return;
			  }
		   }
	if(([anEvent clickCount] > 0) && (([anEvent clickCount] % 2) == 0)){
		   [self mouseDoubleClick:anEvent];
	   } else {
		   [trueMovieView mouseDown:anEvent];
		   [((NiceWindow *)[self window]) mouseDown:anEvent];
	   }
}

- (void)mouseUp:(NSEvent *)anEvent
{
	if(([anEvent type] == NSLeftMouseUp)
	   && (([anEvent modifierFlags] & NSControlKeyMask) == NSControlKeyMask)){ /* This is a control click. */
	   [self rightMouseUp:anEvent];
	   return;
	}
	[((NiceWindow *)[self window]) mouseUp:anEvent];
}

- (void)mouseDoubleClick:(NSEvent *)anEvent
{
    [((NiceWindow *)[self window]) setInitialDrag:anEvent];
    [((NiceWindow *)[self window]) toggleWindowFullScreen];
}

- (void)mouseMoved:(NSEvent *)anEvent
{
	[trueMovieView mouseMoved:anEvent];
	[self smartHideMouseOverOverlays];
}

/* This is so we can capture the right mouse event. */
-(NSMenu *)menuForEvent:(NSEvent *)event
{
	return nil;
}

-(void)rightMouseDown:(NSEvent *)anEvent
{
    [NSMenu popUpContextMenu:[self contextualMenu] withEvent:anEvent forView:self];
}

-(void)rightMouseUp:(NSEvent *)anEvent
{
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    [((NiceWindow *)[self window]) mouseDragged:anEvent];
}

-(BOOL)canAnimateResize
{
    if([trueMovieView respondsToSelector:@selector(canAnimateResize)])
		return [trueMovieView canAnimateResize];
    return YES;
}

-(void)scrollWheel:(NSEvent *)anEvent
{
    float deltaX = [anEvent deltaX], deltaY = [anEvent deltaY];

    if(deltaX) {
        if(deltaX > 0){
            [self ffStart];
            [self ffDo:SCRUB_STEP_DURATION * fabsf(deltaX)];
            [self ffEnd];
        } else {
            [self rrStart];
            [self rrDo:SCRUB_STEP_DURATION * fabsf(deltaX)];
            [self rrEnd];
        }
    }

    if(deltaY) [self scrollWheelResize:deltaY];
}

-(void)scrollWheelResize:(float)delta
{
    [((NiceWindow *)[self window]) resize:delta*5 animate:NO];
}

#pragma mark -
#pragma mark Menus

-(id)myMenu
{
	id myMenu = [[NSMutableArray array] retain];
	id newItem;
	
	newItem = [[[NSMenuItem alloc] initWithTitle:@"Play/Pause"
					      action:@selector(togglePlaying)
				       keyEquivalent:@""] autorelease];
	[newItem setTarget:[((NiceWindow *)[self window]) playButton]];
	[myMenu addObject:newItem];

	[myMenu addObject:[[[[self window]windowController]document] volumeMenu]];

	return [myMenu autorelease];
}

-(id)menuTitle
{
    return trueMovieView ? [trueMovieView menuTitle] : @"";
}

-(id)pluginMenu
{
    return [trueMovieView pluginMenu];
}

-(id)contextualMenu
{	
	[self rebuildMenu];
	return contextMenu;
}

-(void)rebuildMenu
{
	unsigned i;

	while([contextMenu numberOfItems] > 0)
		[contextMenu removeItemAtIndex:0];

	id myMenu = [self myMenu];
	id pluginMenu = [self pluginMenu];
	for(i = 0; i < [myMenu count]; i++)
		[contextMenu addItem:[myMenu objectAtIndex:i]];
	if([pluginMenu count] > 0)
		[contextMenu addItem:[NSMenuItem separatorItem]];
	for(i = 0; i < [pluginMenu count]; i++)
		[contextMenu addItem:[pluginMenu objectAtIndex:i]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
}

#pragma mark -
#pragma mark Pluggables

/* Used to determine the proper size of the window at a given magnification factor. */
-(NSSize)naturalSize
{
    NSSize movieSize = [trueMovieView naturalSize];
    if((movieSize.width == 0) && (movieSize.height == 0))
	return NSMakeSize(320, 240);
    else
	return movieSize;
}

-(double)currentMovieTime
{
	return [trueMovieView currentMovieTime];
}

-(double)percentLoaded{
	if([trueMovieView respondsToSelector:@selector(_percentLoaded)]){
		return [((NSNumber*)[trueMovieView _percentLoaded]) doubleValue];
	}else{
		return 1.0;
	}

}

-(void)setCurrentMovieTime:(double)aDouble
{
    [trueMovieView setCurrentMovieTime:aDouble];
}

-(BOOL)hasEnded:(id)sender
{
	return [trueMovieView hasEnded:sender];
}

-(BOOL)muted
{
	return [trueMovieView muted];
}

-(void)setMuted:(BOOL)aBool
{
	[trueMovieView setMuted:aBool];
}

-(float)volumeWithMute
{
	float volume;
	
	if(trueMovieView)
		volume = [trueMovieView volume];
	else
		volume = 1.0;
	
	if(volume < -2.0)
		volume = -2.0;
	if(volume > 2.0)
		volume = 2.0;

	return volume;
}

-(float)volume
{
	float volume;
	
	if(trueMovieView)
		volume = [trueMovieView volume];
	else
		volume = 1.0;
	
	if(volume < 0.0)
		volume = 0.0;
	if(volume > 2.0)
		volume = 2.0;

	return volume;
}

-(void)setVolume:(float)aVolume
{
	if(aVolume < 0.0)
		aVolume = 0.0;
	if(aVolume > 2.0)
		aVolume = 2.0;
	internalVolume = aVolume;
	[trueMovieView setVolume:internalVolume];

	if([trueMovieView volume] <= 0.0)
		[trueMovieView setMuted:YES];
	else
		[trueMovieView setMuted:NO];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
}

-(double)totalTime
{
	return [trueMovieView totalTime];
}

-(void)drawMovieFrame
{
	[trueMovieView drawMovieFrame];
}

/* Non working code */
#define CROP_STEP1 NSViewMinXMargin | NSViewMaxYMargin
#define CROP_STEP2 NSViewMaxXMargin | NSViewMinYMargin
#define FINAL_SIZING NSViewWidthSizable | NSViewHeightSizable

//crop doesn't work this is more test code
-(IBAction)crop:(id)sender
{
    NSRect newFrame = NSMakeRect(100+20,100+30,100+340,100+270);
    NSRect currentFrame = [((NiceWindow *)[self window]) frame];
    NSRect resizingFrame = currentFrame;
    
    resizingFrame.size.width -= (newFrame.origin.x);
    resizingFrame.size.height -= (newFrame.origin.y);
    [self setAutoresizingMask:CROP_STEP1];
    [((NiceWindow *)[self window]) setFrame:resizingFrame display:YES];
    resizingFrame.size.width -= (currentFrame.size.width - newFrame.size.width);
    resizingFrame.size.height -= (currentFrame.size.height - newFrame.size.height);
    [self setAutoresizingMask:CROP_STEP2];
    [((NiceWindow *)[self window]) setFrame:resizingFrame display:YES];
    [self setAutoresizingMask:FINAL_SIZING];
    [((NiceWindow *)[self window]) setAspectRatio:[((NiceWindow *)[self window]) frame].size];
	
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

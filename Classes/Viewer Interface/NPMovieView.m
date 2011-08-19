/**
 * NPMovieView.m
 * NicePlayer
 *
 * Contains the code for the main view that appears in NiceWindow. It is responsible for
 * creating instances of different movie player views (from plugins) that open movies
 * using different APIs (Quicktime, DVDPlayback, etc.) Basically, it acts as a wrapper
 * for the subview that it dynamically creates, processing most of the various clicks
 * and other events that take place.
 */


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
#import "NPMovieProtocol.h"
#import "NiceWindow.h"
#import "BlankView.h"
#import "NiceDocument.h"
#import "RCMovieView.h"

#define SCRUB_STEP_DURATION 5

@interface NPMovieView(private)
-(NSNumber*)_percentLoaded;
-(void)clearTrueMovieView;
@end

@implementation NPMovieView

-(id)initWithFrame:(NSRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        NSRect subview = NSMakeRect(0, 0, aRect.size.width, aRect.size.height);
        trueMovieView = [[BlankView alloc] initWithFrame:subview];
        contextMenu = [[NSMenu alloc] initWithTitle:@"NicePlayer"];
        wasPlaying = NO;
        [self addSubview:trueMovieView];
        [self setAutoresizesSubviews:YES];
		title = nil;
		fileType = nil;
		fileExtension = nil;
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

-(void)clearTrueMovieView
{
}

-(void)close
{
	//NSLog(@"Close MovieView");
	[self clearTrueMovieView];
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

-(BOOL)openURL:(NSURL *)url
{
    [self clearTrueMovieView];
    if(title) [title release];
    title = [[[[url path] lastPathComponent] stringByDeletingPathExtension] retain];

    if(fileType) [fileType release];
    fileType = nil;
    if(fileExtension) [fileExtension release];
    fileExtension = nil;

    fileExtension = [[[url path] lastPathComponent] pathExtension];
    fileType = NSHFSTypeOfFile([url path]);
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir];
    if(isDir) {
        fileExtension = [NSString stringWithString:@"public.folder"];
        fileType = nil;
    }

    if(fileType && [fileType length] == 0) {
        fileType = nil;
    } else {
        [fileType retain];
    }
    if(fileExtension && [fileExtension length] == 0) {
        fileExtension = nil;
    } else {
        [fileExtension retain];
    }

    BOOL didOpen = NO;
    NSRect subview = NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height);
    NSException *noLoadException = [NSException exceptionWithName:@"NoLoadPlugin" reason:@"CouldntLoad" userInfo:nil];

    @try {
        trueMovieView = [RCMovieView alloc];
        if(!trueMovieView) @throw noLoadException;
        if([trueMovieView initWithFrame:subview]) {
            didOpen = [trueMovieView openURL:url];
        } else {
            [trueMovieView release];
            trueMovieView = nil;
        }
        if(didOpen) {
            [self addSubview:trueMovieView];
            if(![self loadMovie]) @throw noLoadException;
        } else {
            if(trueMovieView) {
                [trueMovieView release];
                trueMovieView = nil;
            }
            @throw noLoadException;
        }
    }
    @catch(NSException *exception) {
        didOpen = NO;
        [self clearTrueMovieView];
        trueMovieView = [[BlankView alloc] initWithFrame:subview];
        [self addSubview:trueMovieView];
    }
    @finally {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
        [self finalProxyViewLoad];
    }
    openedURL = didOpen ? url : nil;
    return didOpen;
}

-(BOOL)loadMovie
{
	BOOL didLoadMovie = [trueMovieView loadMovie];
	
	if(didLoadMovie){
		[trueMovieView setVolume:internalVolume];
	}
	
	return didLoadMovie;
}

-(void)finalProxyViewLoad
{
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
    
    [(<NPMoviePlayer>)trueMovieView stop];
    [[((NiceWindow *)[self window]) playButton] changeToProperButton:[trueMovieView isPlaying]];
}


-(void)ffStart
{
    [[((NiceWindow *)[self window]) ffButton] highlight:YES];
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
    [[((NiceWindow *)[self window]) ffButton] highlight:NO];
    [trueMovieView ffEnd];
    [((NiceWindow *)[self window]) updateByTime:nil];
    
}

-(void)rrStart
{
    [[((NiceWindow *)[self window]) rrButton] highlight:YES];
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
    [[((NiceWindow *)[self window]) rrButton] highlight:NO];
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
			if([anEvent modifierFlags] & NSAlternateKeyMask){
				[trueMovieView stepForward];
				break;
			}
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
			if([anEvent modifierFlags] & NSAlternateKeyMask){
				[trueMovieView stepBackward];
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
			[self timedHideOverlayWithSelector:@"hideOverLayVolume"];
 			break;
		default:
			[super keyUp:anEvent];
    }
}

-(void)showOverLayVolume
{
	[self cancelPreviousPerformRequestsWithSelector:@"hideOverLayVolume"];
	[((NiceWindow *)[self window])automaticShowOverLayVolume];
	[self timedHideOverlayWithSelector:@"hideOverLayVolume"];
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

-(void)timedHideOverlayWithSelector:(NSString *)aStringSelector
{
	[self performSelector:@selector(hideOverlayWithSelector:) withObject:aStringSelector afterDelay:1.0];
}

-(void)cancelPreviousPerformRequestsWithSelector:(NSString *)aStringSelector
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(hideOverlayWithSelector:)
											   object:aStringSelector];
}

-(void)hideOverlayWithSelector:(NSString *)aStringSelector
{
	[[self window] performSelector:sel_registerName([aStringSelector cString])];
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
    dragButton = NO;
	
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
    if(!dragButton)
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

-(double)currentMovieFrameRate
{
    return [trueMovieView currentMovieFrameRate];
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

-(void)setLoopMode:(NSQTMovieLoopMode)flag
{
	[trueMovieView setLoopMode:flag];
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

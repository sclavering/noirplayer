/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirMovieView.h"
#import "NoirWindow.h"
#import "NoirDocument.h"

#define SCRUB_STEP_DURATION 5

@implementation NoirMovieView

-(NoirWindow*)noirWindow
{
    return (NoirWindow*) self.window;
}

-(instancetype)initWithFrame:(NSRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        [self setAutoresizesSubviews:YES];
    }
    return self;
}

-(void)close
{
    [qtlayer setMovie:nil];
    qtlayer = nil;
    movie = nil;
}

-(void)dealloc
{
    [self close];
    [super dealloc];
}

-(void)openMovie:aMovie
{
    qtlayer = [QTMovieLayer layerWithMovie:aMovie];
    qtlayer.frame = self.frame;
    [self setWantsLayer:true];
    self.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    [self.layer insertSublayer:qtlayer atIndex:0];
    qtlayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    movie = aMovie;
}

-(NSView *)hitTest:(NSPoint)aPoint
{
    if(NSMouseInRect(aPoint, self.frame, NO))
        return self;
    return nil;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark -
#pragma mark Keyboard Events

-(void)keyDown:(NSEvent *)anEvent
{
    if((anEvent.modifierFlags & NSShiftKeyMask)) return;
    
    switch([anEvent.characters characterAtIndex:0]){
        case ' ':
            if(!anEvent.ARepeat) [[self.window noirDoc] togglePlayingMovie];
            break;
        case NSRightArrowFunctionKey:
            if(!anEvent.ARepeat) [[self.window noirDoc] startStepping];
            [[self.window noirDoc] stepBy:SCRUB_STEP_DURATION];
            break;
        case NSLeftArrowFunctionKey:
            if(anEvent.modifierFlags & NSCommandKeyMask){
                [[self.window noirDoc] setCurrentMovieTime:0];
                break;
            }
            if(!anEvent.ARepeat) [[self.window noirDoc] startStepping];
            [[self.window noirDoc] stepBy:-SCRUB_STEP_DURATION];
            break;
        case NSUpArrowFunctionKey:
            [[self.window noirDoc] incrementVolume];
            break;
        case NSDownArrowFunctionKey:
            [[self.window noirDoc] decrementVolume];
            break;
        case 0x1B:
            [[self noirWindow] unFullScreen];
            break;
        default:
            [super keyDown:anEvent];
    }
}

-(void)keyUp:(NSEvent*)anEvent
{
    if((anEvent.modifierFlags & NSShiftKeyMask)) return;

    switch([anEvent.characters characterAtIndex:0]){
        case ' ':
            break;
        case NSRightArrowFunctionKey:
            [[self.window noirDoc] endStepping];
            break;
        case NSLeftArrowFunctionKey:
            [[self.window noirDoc] endStepping];
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

@end

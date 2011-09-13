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
* Portions created by the Initial Developer are Copyright (C) 2004-2006
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

#import "NiceDocument.h"
#import "ControlPlay.h"
#import "NPApplication.h"


@interface QTMovie(IdlingAdditions)
-(QTTime)maxTimeLoaded;
@end

@implementation NiceDocument

- (id)init
{
    self = [super init];
    if(self){
        preSteppingState = PSS_INACTIVE;
        menuObjects = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(rebuildMenu)
                                                     name:@"RebuildAllMenus"
                                                   object:nil];		
    }
    return self;
}

-(void)dealloc
{
    if(menuObjects != nil){
        for(NSUInteger i = 0; i < [menuObjects count]; i++)
            [[self movieMenu] removeItem:[menuObjects objectAtIndex:i]];
        [menuObjects release];
    }
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark -
#pragma mark File Operations

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    id tDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:0],@"MajorVersion",
        [NSNumber numberWithInt:1],@"MinorVersion",
        [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:[self volume]], @"Volume",nil],
      @"Contents", nil];
    NSString* tErrror = nil;
    NSData* tData = [NSPropertyListSerialization dataFromPropertyList:tDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&tErrror];
    return tData;
}

// Called when a file is dropped on the app icon
-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)docType error:(NSError **)outError
{
    movie = [QTMovie movieWithURL:url error:outError];
    [theWindow setTitleWithRepresentedFilename:[url path]];
    [NSApp changeWindowsItem:theWindow title:[theWindow title] filename:YES];
    [NSApp updateWindowsItem:theWindow];
    return movie ? YES : NO;
}

#pragma mark -
#pragma mark Window Information

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
    wasPlayingBeforeMini = [self isPlaying];
    [self pauseMovie];
}

- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
    if(wasPlayingBeforeMini) [self playMovie];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    [NSApp updateWindowsItem:theWindow];
    [[self window] updateVolume];
	[[self window] orderFront:aController];
    [theMovieView openMovie:movie];
    NSSize aSize = [self naturalSize];
    [theWindow setAspectRatio:aSize];
    [theWindow setMinSize:NSMakeSize(150 * aSize.width / aSize.height, 150)];
    [theWindow initialDefaultSize];
    [theWindow setTitle:[theWindow title]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
}

- (void)makeWindowControllers
{
	NSWindowController *controller = [[NSWindowController alloc] initWithWindowNibName:@"NiceDocument" owner:self];
    [self addWindowController:controller];
	[controller release];
}

- (void)showWindows
{
    [super showWindows];
    [(NiceWindow *)[self window] setupOverlays];
}

-(NSMenu *)movieMenu
{
    return [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Movie",@"Movie")] submenu];
}

/* Always call this method by raising the notification "RebuildAllMenus" otherwise
stuff won't work properly! */
-(void)rebuildMenu
{
    // xxx this ought to show a Volume menu on the Movie menu

    if(menuObjects != nil) {
        for(NSUInteger i = 0; i < [menuObjects count]; i++)
            [[self movieMenu] removeItem:[menuObjects objectAtIndex:i]];
        [menuObjects release];
        menuObjects = nil;
    }
    
    if([[self window] isKeyWindow]) {
        menuObjects = [[NSMutableArray array] retain];
        id videoMenuItems = [self videoMenuItems];
        for(NSUInteger i = 0; i < [videoMenuItems count]; i++) {
            [[self movieMenu] insertItem:[videoMenuItems objectAtIndex:i] atIndex:i];
            [menuObjects addObject:[videoMenuItems objectAtIndex:i]];
        }
    }
}

-(NSMutableArray*)videoMenuItems
{
    id items = [[[NSMutableArray array] retain] autorelease];

    id newItem = [[[NSMenuItem alloc] initWithTitle:@"Play/Pause" action:@selector(togglePlayingMovie) keyEquivalent:@""] autorelease];
	[newItem setTarget:self];
	[items addObject:newItem];

    newItem = [[[NSMenuItem alloc] initWithTitle:@"Video Tracks" action:NULL keyEquivalent:@""] autorelease];
    [newItem setTarget:self];
	[newItem setSubmenu:[self videoTrackMenu]];
    [items addObject:newItem];

    newItem = [[[NSMenuItem alloc] initWithTitle:@"Audio Tracks" action:NULL keyEquivalent:@""] autorelease];
    [newItem setTarget:self];
	[newItem setSubmenu:[self audioTrackMenu]];
    [items addObject:newItem];

    newItem = [[[NSMenuItem alloc] initWithTitle:@"Aspect Ratio" action:NULL keyEquivalent:@""] autorelease];
    [newItem setSubmenu:[self aspectRatioMenu]];
    [items addObject:newItem];

    return items;
}

-(NSMenu*)audioTrackMenu
{
    NSMenu* tReturnMenu = [[[NSMenu alloc] init] autorelease];
    NSArray* tArray = [movie tracksOfMediaType:@"soun"];
    for(NSUInteger i = 0; i < [tArray count]; i++) {
        QTTrack* tTrack = [tArray objectAtIndex:i];
        NSDictionary* tDict = [tTrack trackAttributes];
        NSMenuItem* tItem = [[[NSMenuItem alloc] initWithTitle:[tDict objectForKey:@"QTTrackDisplayNameAttribute"] action:@selector(toggleTrack:) keyEquivalent:@""] autorelease];
        [tItem setRepresentedObject:tTrack];
        [tItem setTarget:self];
        if([tTrack isEnabled]) [tItem setState:NSOnState];
        [tReturnMenu addItem:tItem];
    }
    return tReturnMenu;
}

-(NSMenu*)videoTrackMenu
{
    NSMenu* tReturnMenu = [[[NSMenu alloc] init] autorelease];
    NSArray* tArray = [movie tracksOfMediaType:@"vide"];
    for(NSUInteger i = 0; i < [tArray count]; i++) {
        QTTrack* tTrack = [tArray objectAtIndex:i];
        NSDictionary* tDict = [tTrack trackAttributes];
        NSMenuItem* tItem = [[[NSMenuItem alloc] initWithTitle:[tDict objectForKey:@"QTTrackDisplayNameAttribute"] action:@selector(toggleTrack:) keyEquivalent:@""] autorelease];
        [tItem setRepresentedObject:tTrack];
        [tItem setTarget:self];
        if([tTrack isEnabled]) [tItem setState:NSOnState];
        [tReturnMenu addItem:tItem];
    }
    return tReturnMenu;
}

-(NSMenu*)aspectRatioMenu
{
    NSMenu* m = [[[NSMenu alloc] init] autorelease];
    NSString* labels[] = { @"Natural", @"16:9", @"16:10", @"4:3" };
    float values[] = { 0, 16.0 / 9.0, 16.0 / 10.0, 4.0 / 3.0 };
    for(int i = 0; i != 4; ++i) {
        NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:labels[i] action:@selector(selectAspectRatio:) keyEquivalent:@""] autorelease];
        [mi setRepresentedObject:[NSNumber numberWithFloat:values[i]]];
        [mi setTarget:self];
        [m addItem:mi];
    }
    return m;
}

-(IBAction)toggleTrack:(id)sender
{
    [[sender representedObject] setEnabled:![[sender representedObject] isEnabled]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:self];
}

-(void)selectAspectRatio:(id)sender
{
    float val = [[sender representedObject] floatValue];
    NSSize ratio = val ? NSMakeSize(val, 1) : [self naturalSize];
    [theWindow setAspectRatio:ratio];
    [theWindow resizeToAspectRatio];
}

-(id)window
{
    return theWindow;
}

-(double)percentLoaded
{
    NSTimeInterval tDuration;
    QTGetTimeInterval([movie duration], &tDuration);
    NSTimeInterval tMaxLoaded;
    QTGetTimeInterval([movie maxTimeLoaded], &tMaxLoaded);
    return tMaxLoaded / tDuration;
}

-(NSSize)naturalSize
{
    NSSize sz = [[movie attributeForKey: QTMovieNaturalSizeAttribute] sizeValue];
    return sz.width && sz.height ? sz : NSMakeSize(320, 240);
}

#pragma mark Play/Pause

-(BOOL)isPlaying
{
    return [movie rate] != 0.0;
}

-(void)togglePlayingMovie
{
    [self isPlaying] ? [self pauseMovie] : [self playMovie];
}

-(void)playMovie
{
    [movie play];
    [[theWindow playButton] changeToProperButton:[self isPlaying]];
}

-(void)pauseMovie
{
    [movie stop];
    [[theWindow playButton] changeToProperButton:[self isPlaying]];
}

#pragma mark Stepping

-(void)startStepping
{
    if(preSteppingState == PSS_INACTIVE) preSteppingState = [self isPlaying] ? PSS_PLAYING : PSS_STOPPED;
    [self pauseMovie];
}

-(void)stepBy:(int)seconds
{
    [self setCurrentMovieTime:([self currentMovieTime] + seconds)];
    [theMovieView drawMovieFrame];
    [theWindow updateByTime:nil];
}

-(void)endStepping
{
    if(preSteppingState == PSS_PLAYING) [self playMovie];
    preSteppingState = PSS_INACTIVE;
    [theWindow updateByTime:nil];
}

#pragma mark Time

-(double)totalTime
{
    QTTime duration = [movie duration];
    return duration.timeValue / duration.timeScale;
}

-(double)currentMovieTime
{
    QTTime current = [movie currentTime];
    return current.timeValue / current.timeScale;
}

-(void)setCurrentMovieTime:(double)newMovieTime
{
    [movie setCurrentTime:QTMakeTime(newMovieTime, 1)];
}

-(double)currentTimeAsFraction
{
    return [self currentMovieTime] / [self totalTime];
}

-(void)setMovieTimeByFraction:(double)when
{
    [self setCurrentMovieTime:[self totalTime] * when];
}

#pragma mark Volume

-(float)volume
{
    float volume = [movie volume];
    if(volume < 0.0) volume = 0.0;
    if(volume > 2.0) volume = 2.0;
    return volume;
}

-(void)setVolume:(float)aVolume
{
    if(aVolume < 0.0) aVolume = 0.0;
    if(aVolume > 2.0) aVolume = 2.0;
    [movie setVolume:aVolume];
    [movie setMuted:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
}

-(void)incrementVolume
{
    [self setVolume:[self volume] + 0.1];
    [theWindow updateVolume];
}

-(void)decrementVolume
{
    [self setVolume:[self volume] - 0.1];
    [theWindow updateVolume];
}

@end

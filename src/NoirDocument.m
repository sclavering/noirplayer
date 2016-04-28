/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirDocument.h"
#import "NoirMovieQT.h"


@implementation NoirDocument

- (instancetype)init
{
    self = [super init];
    if(self){
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
        for(id item in menuObjects) [[self movieMenu] removeItem:item];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark File Operations

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    id tDict = @{@"MajorVersion": @0,
        @"MinorVersion": @1,
        @"Contents": @{@"Volume": @([self volume])}};
    NSString* tErrror = nil;
    NSData* tData = [NSPropertyListSerialization dataFromPropertyList:tDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&tErrror];
    return tData;
}

// Called when a file is dropped on the app icon
-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)docType error:(NSError **)outError
{
    _movie = [[NoirMovieQT alloc] initWithURL:url error:outError];
    if(!_movie) return false;
    [theWindow setTitleWithRepresentedFilename:url.path];
    [NSApp changeWindowsItem:theWindow title:theWindow.title filename:YES];
    [NSApp updateWindowsItem:theWindow];
    return true;
}

-(void)closeMovie {
    [_movie close];
}

#pragma mark -
#pragma mark Window Information

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
    wasPlayingBeforeMini = [_movie isPlaying];
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
    [[self window] orderFront:aController];
    [_movie showInView:theWindow.contentView];
    NSSize aSize = [_movie naturalSize];
    [theWindow setAspectRatio:aSize];
    theWindow.minSize = NSMakeSize(150 * aSize.width / aSize.height, 150);
    [theWindow resizeWithSize:NSMakeSize(theWindow.aspectRatio.width, theWindow.aspectRatio.height) animate:NO];
    [theWindow setTitle:theWindow.title];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
}

- (void)makeWindowControllers
{
    NSWindowController *controller = [[NSWindowController alloc] initWithWindowNibName:@"NoirDocument" owner:self];
    [self addWindowController:controller];
}

-(NSMenu *)movieMenu
{
    return [NSApp.mainMenu itemWithTitle:NSLocalizedString(@"Movie",@"Movie")].submenu;
}

/* Always call this method by raising the notification "RebuildAllMenus" otherwise
stuff won't work properly! */
-(void)rebuildMenu
{
    // xxx this ought to show a Volume menu on the Movie menu

    if(menuObjects != nil) {
        for(id item in menuObjects) [[self movieMenu] removeItem:item];
        menuObjects = nil;
    }

    if([[self window] isKeyWindow]) {
        menuObjects = [NSMutableArray array];
        id videoMenuItems = [self videoMenuItems];
        for(NSUInteger i = 0; i < [videoMenuItems count]; i++) {
            [[self movieMenu] insertItem:videoMenuItems[i] atIndex:i];
            [menuObjects addObject:videoMenuItems[i]];
        }
    }
}

-(NSMutableArray*)videoMenuItems
{
    id items = [NSMutableArray array];

    id newItem = [[NSMenuItem alloc] initWithTitle:@"Play/Pause" action:@selector(togglePlayingMovie) keyEquivalent:@""];
    [newItem setTarget:self];
    [items addObject:newItem];

    newItem = [[NSMenuItem alloc] initWithTitle:@"Video Tracks" action:NULL keyEquivalent:@""];
    [newItem setTarget:self];
    [newItem setSubmenu:[_movie videoTrackMenu]];
    [items addObject:newItem];

    newItem = [[NSMenuItem alloc] initWithTitle:@"Audio Tracks" action:NULL keyEquivalent:@""];
    [newItem setTarget:self];
    [newItem setSubmenu:[_movie audioTrackMenu]];
    [items addObject:newItem];

    newItem = [[NSMenuItem alloc] initWithTitle:@"Aspect Ratio" action:NULL keyEquivalent:@""];
    [newItem setSubmenu:[self aspectRatioMenu]];
    [items addObject:newItem];

    return items;
}

-(NSMenu*)aspectRatioMenu
{
    NSMenu* m = [[NSMenu alloc] init];
    NSString* labels[] = { @"Natural", @"16:9", @"16:10", @"4:3" };
    float values[] = { 0, 16.0 / 9.0, 16.0 / 10.0, 4.0 / 3.0 };
    for(int i = 0; i != 4; ++i) {
        NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:labels[i] action:@selector(selectAspectRatio:) keyEquivalent:@""];
        mi.representedObject = @(values[i]);
        mi.target = self;
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
    NSSize ratio = val ? NSMakeSize(val, 1) : [_movie naturalSize];
    [theWindow setAspectRatio:ratio];
    [theWindow resizeToAspectRatio];
}

-(id)window
{
    return theWindow;
}

#pragma mark Play/Pause

-(void)togglePlayingMovie
{
    [_movie isPlaying] ? [self pauseMovie] : [self playMovie];
}

-(void)playMovie
{
    [_movie play];
    [theWindow updatePlayButton:[_movie isPlaying]];
}

-(void)pauseMovie
{
    [_movie pause];
    [theWindow updatePlayButton:[_movie isPlaying]];
}

#pragma mark Stepping

-(void)startStepping
{
    if(_isStepping) return;
    _isStepping = true;
    _wasPlayingBeforeStepping = [_movie isPlaying];
    [self pauseMovie];
}

-(void)stepBy:(int)seconds {
    [self.movie adjustCurrentTimeBySeconds:seconds];
    [theWindow updateTimeInterface];
}

-(void)endStepping
{
    _isStepping = false;
    if(_wasPlayingBeforeStepping) [self playMovie];
    [theWindow updateTimeInterface];
}

#pragma mark Volume

-(float)volume
{
    float volume = [_movie volume];
    if(volume < 0.0) volume = 0.0;
    if(volume > 2.0) volume = 2.0;
    return volume;
}

-(void)setVolume:(float)aVolume
{
    if(aVolume < 0.0) aVolume = 0.0;
    if(aVolume > 2.0) aVolume = 2.0;
    [_movie setVolume:aVolume];
}

-(void)incrementVolume
{
    [self setVolume:[self volume] + 0.1];
    [theWindow updateVolumeIndicator];
}

-(void)decrementVolume
{
    [self setVolume:[self volume] - 0.1];
    [theWindow updateVolumeIndicator];
}

@end

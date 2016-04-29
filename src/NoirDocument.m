/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirDocument.h"
#import "NoirMovieQT.h"


@implementation NoirDocument

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
}

- (void)makeWindowControllers
{
    NSWindowController *controller = [[NSWindowController alloc] initWithWindowNibName:@"NoirDocument" owner:self];
    [self addWindowController:controller];
}

// The menu items have .representedObject set to a float NSNumber via the "User Defined Runtime Attributes" field in Xcode.
-(IBAction)selectAspectRatio:(id)sender {
    id obj = [sender representedObject];
    NSSize ratio = obj ? NSMakeSize([obj floatValue], 1) : [_movie naturalSize];
    [theWindow setAspectRatio:ratio];
    [theWindow resizeToAspectRatio];
}

-(id)window
{
    return theWindow;
}

#pragma mark Play/Pause

-(IBAction)togglePlayingMovie:(id)sender {
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

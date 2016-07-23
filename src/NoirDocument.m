/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirDocument.h"


@implementation NoirDocument

#pragma mark -
#pragma mark File Operations

-(NSData *) dataRepresentationOfType:(NSString *)aType {
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    id tDict = @{
        @"MajorVersion": @0,
        @"MinorVersion": @1,
        @"Contents": @{
            @"VolumePercent": @(self.movie.volumePercent),
        },
    };
    NSString* tErrror = nil;
    NSData* tData = [NSPropertyListSerialization dataFromPropertyList:tDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&tErrror];
    return tData;
}

// Called when a file is dropped on the app icon
-(BOOL) readFromURL:(NSURL *)url ofType:(NSString *)docType error:(NSError **)outError {
    _movie = [[LAVPMovie alloc] initWithURL:url error:outError];
    if(!_movie) return false;
    [theWindow setTitleWithRepresentedFilename:url.path];
    [NSApp changeWindowsItem:theWindow title:theWindow.title filename:YES];
    [NSApp updateWindowsItem:theWindow];
    return true;
}

#pragma mark -
#pragma mark Window Information

-(void) windowDidMiniaturize:(NSNotification *)aNotification {
    wasPlayingBeforeMini = !self.movie.paused;
    self.movie.paused = true;
}

-(void) windowDidDeminiaturize:(NSNotification *)aNotification {
    if(wasPlayingBeforeMini) self.movie.paused = false;
}

-(void) windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    [NSApp updateWindowsItem:theWindow];
    [theWindow orderFront:aController];
    [theWindow showMovie:_movie];
    [theWindow setTitle:theWindow.title];
}

-(void) makeWindowControllers {
    NSWindowController *controller = [[NSWindowController alloc] initWithWindowNibName:@"NoirDocument" owner:self];
    [self addWindowController:controller];
}

@end

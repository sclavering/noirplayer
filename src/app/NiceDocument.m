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

#define VOLUME_ITEM -43


@implementation NiceDocument

- (id)init
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
        [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithFloat:[theMovieView volume]], @"Volume",
                nil
            ], @"Contents",
            nil];
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
    NSSize aSize = [theMovieView naturalSize];
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

-(IBAction)switchVolume:(NSMenuItem*)sender{
	[theMovieView setVolume:[[sender representedObject] intValue]/100.0];
}

-(IBAction)increaseVolume:(id)sender{
	[theMovieView incrementVolume];
}

-(IBAction)decreaseVolume:(id)sender{
	[theMovieView decrementVolume];
}

-(NSMenuItem*)volumeMenu{
	NSMenuItem* tHeading = [[[NSMenuItem alloc] init] autorelease];
	[tHeading setTitle:NSLocalizedString(@"Volume",@"Volume Menu item")];

	NSMenu* tMenu = [[[NSMenu alloc]init] autorelease];
	
	NSMenuItem* tItem = [[[NSMenuItem alloc] init] autorelease];
	[tItem setTitle:NSLocalizedString(@"Increase Volume",@"Increase Volume menu item")];
	[tItem setKeyEquivalent:@"="];
	[tItem setTarget:self];
    [tItem setKeyEquivalentModifierMask:0];

	[tItem setAction:@selector(increaseVolume:)];
	[tMenu addItem:tItem];
	
	tItem = [[[NSMenuItem alloc] init] autorelease];
	[tItem setTitle:NSLocalizedString(@"Decrease Volume",@"Increase Volume menu item")];
	[tItem setKeyEquivalent:@"-"];
		[tItem setKeyEquivalentModifierMask:0];

	[tItem setTarget:self];
	[tItem setAction:@selector(decreaseVolume:)];
	[tMenu addItem:tItem];
	
	[tHeading setSubmenu:tMenu];
	
	return tHeading;
}

/* Always call this method by raising the notification "RebuildAllMenus" otherwise
stuff won't work properly! */
-(void)rebuildMenu
{
    // xxx this ought to show a Volume menu on the Movie menu

    id pluginMenu = [theMovieView pluginMenu];
    if(!pluginMenu)
		pluginMenu = [NSMutableArray array];

    if(menuObjects != nil) {
        for(NSUInteger i = 0; i < [menuObjects count]; i++)
            [[self movieMenu] removeItem:[menuObjects objectAtIndex:i]];
        [menuObjects release];
        menuObjects = nil;
    }
    
    if([[self window] isKeyWindow]) {
        menuObjects = [[NSMutableArray array] retain];
        for(NSUInteger i = 0; i < [pluginMenu count]; i++) {
            [[self movieMenu] insertItem:[pluginMenu objectAtIndex:i] atIndex:i];
            [menuObjects addObject:[pluginMenu objectAtIndex:i]];
        }
    }
}

-(id)window
{
    return theWindow;
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

#pragma mark Volume

-(float)volume
{
	return [theMovieView volume];
}

@end

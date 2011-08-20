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
#import "NiceUtilities.h"
#import "NiceWindow/NiceWindowController.h"
#import "ControlPlay.h"
#import "ArrayExtras.h"

#define VOLUME_ITEM -43

BOOL rejectSelf(id each,void* context){
    return [each isEqual:[(NiceDocument*)context window]];
}

NSInteger sortByMain(id v1, id v2, void* context){
    if([v1 isEqualTo:v2])
        return NSOrderedSame;
    if([[NSScreen mainScreen] isEqualTo: v1]){
        return NSOrderedAscending;
    }
    
    return NSOrderedAscending;
}

BOOL findWindowScreen(id each, void* context){
    return [[each screen] isEqual:(NSScreen*)context];
}

BOOL findOpenPoint(id eachwin, void* context){
    
    NSMutableDictionary* tContext =(NSMutableDictionary*) context;
    
    NSValue* tPoint =[tContext objectForKey:@"tPoint"];
    NiceDocument* tSelf =[tContext objectForKey:@"self"];
    NSRect tWinRect = [eachwin frame];
    NSRect tNewRect = NSMakeRect([tPoint pointValue].x,[tPoint pointValue].y,[[tSelf window] frame].size.width,[[tSelf window] frame].size.height);
    NSRect tSubScreenRect =[[tContext objectForKey:@"tSubScreenRect"] rectValue];
    
    return NSIntersectsRect(tWinRect,tNewRect) || !NSContainsRect(tSubScreenRect,tNewRect);
}

void findSpace(id each, void* context, BOOL* endthis){
    NSMutableDictionary* tContext =(NSMutableDictionary*) context;
    NSRect tSubScreenRect = [each visibleFrame];
    [tContext setObject:[NSValue valueWithRect:tSubScreenRect] forKey:@"tSubScreenRect"];
    NiceDocument* tSelf = [tContext objectForKey:@"self"];

    
    for(float j = tSubScreenRect.origin.y + tSubScreenRect.size.height - [[tSelf window] frame].size.height; j >= tSubScreenRect.origin.y; j -= [[tSelf window] frame].size.height){
        for(float i = tSubScreenRect.origin.x; i < tSubScreenRect.origin.x + tSubScreenRect.size.width; i+= [[tSelf window] frame].size.width){
            NSValue* tPoint= [NSValue valueWithPoint:NSMakePoint(i,j)];
            [tContext setObject:tPoint forKey:@"tPoint"];
            if(nil == [[tContext objectForKey:@"tMovieWindows"] detectUsingFunction:findOpenPoint context:(void*)tContext]){
                STDoBreak(endthis);
            }
            tPoint = nil;
        }
    }
}

#import "NPApplication.h"

@interface NiceDocument(Private)



@end


@implementation NiceDocument

- (id)init
{
    self = [super init];
    if(self){
        hasRealMovie = NO;
        asffrrTimer = nil;
        movieMenuItem = nil;
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
    int i;
    
    if(movieMenuItem != nil && ([[self movieMenu] indexOfItem:movieMenuItem] != -1))
        [[self movieMenu] removeItem:movieMenuItem];
    
    if(menuObjects != nil){
        for(i = 0; i < (int)[menuObjects count]; i++)
            [[self movieMenu] removeItem:[menuObjects objectAtIndex:i]];
        [menuObjects release];
    }
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [theCurrentURL release];
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

/**
* This gets called automatically when a user attempts to open a document via the open menu.
 */
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
    return [self readFromURL:[NSURL fileURLWithPath:fileName] ofType:docType];
}

/**
* Things to do for a new file passed in. This gets called by the document controller automatically when
 * files are dropped onto the app icon.
 */
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)docType
{
    // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    if(theCurrentURL)
        [theCurrentURL release];
    theCurrentURL = [url retain];
    return YES;
}

/**
* Try to load a URL.
 * TODO: Actually check for errors.
 */
-(void)loadURL:(NSURL *)url firstTime:(BOOL)isFirst
{
	if([[NSURL URLWithString:@"placeholder://URL_Placeholder"] isEqualTo:url])
		return;
    [self readFromURL:url ofType:nil];
    [self finalOpenURLFirstTime:isFirst];
    [self updateAfterLoad];
}

/**
* Try to open a URL. If it fails, load a blank window image. If it succeeds, set up the proper aspect ratio,
 * and title information.
 */
-(BOOL)finalOpenURLFirstTime:(BOOL)isFirst
{   
    /* Try to load the movie */
    if(![theMovieView openURL:theCurrentURL]){
        hasRealMovie = NO;
        return NO;
    }
    hasRealMovie = YES;
    
    /* Initialize the window stuff for movie playback. */
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
    [theWindow restoreVolume];
    [self calculateAspectRatio];
    if(isFirst)
        [theWindow initialDefaultSize];
    else
        [theWindow resizeToAspectRatio];
    [theWindow setTitleWithRepresentedFilename:[theCurrentURL path]];
    [theWindow setTitle:[theWindow title]];
    [NSApp changeWindowsItem:theWindow title:[theWindow title] filename:YES];
    [NSApp updateWindowsItem:theWindow];
    
    return YES;
}

#pragma mark Window Information

-(BOOL)isActive
{
    return hasRealMovie;
}

-(BOOL)isPlaying
{
    return [theMovieView isPlaying];
}

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
    wasPlayingBeforeMini = [(NPMovieView *)theMovieView isPlaying];
    [(NPMovieView *)theMovieView stop];
}

- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
    [theWindow restoreVolume];
    if(wasPlayingBeforeMini)
	[theMovieView start];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];

    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    if(theCurrentURL == nil){
        [NSApp addWindowsItem:theWindow title:@"NicePlayer" filename:NO];
    } 
    
    [self updateAfterLoad];
	[self repositionAfterLoad];
	[[self window] orderFront:aController];
}

/**
* Update the UI after loading a movie by doing things such as scaling to the proper aspect ratio and
 * refreshing GUI items.
 */
-(void)updateAfterLoad
{
    [NSApp updateWindowsItem:theWindow];
    [self calculateAspectRatio];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RebuildAllMenus" object:nil];
    [[self window] updateVolume];
}


-(void)repositionAfterLoad
{
    int tScreenPref = -1;
    
    NSScreen* tScreen = [NSScreen mainScreen];
    NSArray* tScreens = [NSScreen screens];
    
    if(tScreenPref > 0 && (tScreenPref < (int)[tScreens count])){
        tScreen = [tScreens objectAtIndex:tScreenPref];
    }  
        
    NSValue* tPoint = nil;
      
    NSArray* tMovieWindows = [[NSApp movieWindows] rejectUsingFunction:rejectSelf context:(void*)self];
    
    
    NSMutableDictionary* tContext = [NSMutableDictionary dictionaryWithObjectsAndKeys:self,@"self",tMovieWindows,@"tMovieWindows", nil];

    
    if(tScreenPref < 0){
        id tArray =[[NSScreen screens] sortedArrayUsingFunction:sortByMain context:nil];
        [tArray doUsingFunction:findSpace context:(void*)tContext];
    }else{
        BOOL tDummy;
        findSpace(tScreen,(void*)tContext,&tDummy);
    }
    
    tPoint = [tContext objectForKey:@"tPoint"];
    
    
    if(tPoint == nil){

        id tWindow = [[NSApp movieWindows] detectUsingFunction:findWindowScreen context:(void*)tScreen];
        [[self window] cascadeTopLeftFromPoint:[tWindow frame].origin];
    }else{
        [[self window] setFrameOrigin:[tPoint pointValue]];
    }
}

- (void)makeWindowControllers{
	NiceWindowController *controller = [[NiceWindowController alloc] initWithWindowNibName:@"NiceDocument" owner:self];
    [self addWindowController:controller];
	[controller release];
}

- (void)showWindows
{
    [super showWindows];
    [(NiceWindow *)[self window] setupOverlays];
}

/**
* If movie has ended, then set the proper images for the controls and play the next movie.
 */
-(void)movieHasEnded
{
    [[theWindow playButton] setImage:[NSImage imageNamed:@"play"]];
    [[theWindow playButton] setAlternateImage:[NSImage imageNamed:@"playClick"]];
    if([theMovieView wasPlaying] && ![(NiceWindow*)[self window] scrubberInUse])
        if([[self window] isFullScreen])
            [[self window] unFullScreen];
}

-(NSMenu *)movieMenu
{
    return [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Movie",@"Movie")] submenu];
}

-(IBAction)switchVolume:(NSMenuItem*)sender{
	[theMovieView setVolume:[[sender representedObject] intValue]/100.0];
}
-(IBAction)mute:(id)sender{
	[theMovieView setMuted:![theMovieView muted]];
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
	[tItem setTitle:NSLocalizedString(@"Mute",@"Mute menu item")];
	[tItem setKeyEquivalent:@"del"];
	[tItem setState: [theMovieView muted] ? NSOnState: NSOffState];
	[tItem setTarget:self];
	[tItem setAction:@selector(mute:)];
	[tMenu addItem:tItem];
	
	tItem = [[[NSMenuItem alloc] init] autorelease];
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
	
	[tMenu addItem:[NSMenuItem separatorItem]];



	for(int i= 200; i>=0;i-=20){
			tItem = [[[NSMenuItem alloc] init] autorelease];
			[tItem setTitle:[NSString stringWithFormat:@"%d%%",i]];
			
			int tInt =(int)(fabsf([theMovieView volumeWithMute]) * 10);
			
			if(tInt == i /10)
				[tItem setState:NSOnState];
			else if(tInt > i /10
					&& tInt < (i /10) +2 )
				[tItem setState:NSMixedState];
			else
				[tItem setState:NSOffState];

			[tItem setTag:VOLUME_ITEM];
			[tItem setRepresentedObject:[NSNumber numberWithInt:i]];
			[tItem setTarget:self];
			[tItem setAction:@selector(switchVolume:)];
			[tMenu addItem:tItem];
	}
	
	[tHeading setSubmenu:tMenu];
	
	return tHeading;
}

/* Always call this method by raising the notification "RebuildAllMenus" otherwise
stuff won't work properly! */
-(void)rebuildMenu
{
    // xxx this ought to show a Volume menu on the Movie menu

    int i;
    id pluginMenu = [theMovieView pluginMenu];
    if(!pluginMenu)
		pluginMenu = [NSMutableArray array];

    if(movieMenuItem != nil && ([[self movieMenu] indexOfItem:movieMenuItem] != -1)){
        [[self movieMenu] removeItem:movieMenuItem];
        movieMenuItem = nil;
    }
    
    if(menuObjects != nil){
        for(i = 0; i < (int)[menuObjects count]; i++)
            [[self movieMenu] removeItem:[menuObjects objectAtIndex:i]];
        [menuObjects release];
        menuObjects = nil;
    }
    
	id tMenuTitle =[theMovieView menuTitle];
	if(tMenuTitle == nil)
		tMenuTitle = @"Untitled Movie";
    movieMenuItem = [[NSMenuItem alloc] initWithTitle:tMenuTitle action:nil keyEquivalent:@""];

    if([[self window] isKeyWindow]) {
        menuObjects = [[NSMutableArray array] retain];
        [movieMenuItem setEnabled:NO];
        [[self movieMenu] insertItem:movieMenuItem atIndex:0];
        for(i = (int)[pluginMenu count] - 1; i >= 0; i--){	// Reverse iteration for easier addition
            [[self movieMenu] insertItem:[pluginMenu objectAtIndex:i] atIndex:1];
            [menuObjects addObject:[pluginMenu objectAtIndex:i]];
        }
    }
}

-(id)window
{
    return theWindow;
}

- (NSSize)calculateAspectRatio
{
    NSSize aSize = [theMovieView naturalSize];
		[theWindow setAspectRatio:aSize];
		[theWindow setMinSize:NSMakeSize((aSize.width/aSize.height)*150,150)];
	return aSize;
}

#pragma mark Interface

-(void)play:(id)sender
{
    [theMovieView start];
}

-(void)pause:(id)sender
{
    [theMovieView stop];
}

-(float)volume
{
	return [theMovieView volume];
}

@end

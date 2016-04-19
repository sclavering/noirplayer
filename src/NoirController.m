/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirController.h"
#import "NoirApp.h"
#import "NoirDocument.h"

id controller;

@implementation NoirController

+(id)controller
{
    return controller;
}

+(void)setController:(id)aNoirController
{
    controller = aNoirController;
}

-(void)awakeFromNib
{
    lastMouseLocation = NSMakePoint(0, 0);
    fullScreenMode = NO;
    mouseMoveTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkMouseLocation:) userInfo:nil repeats:YES]; // Auto-hides mouse.
    lastCursorMoveDate = [[NSDate alloc] init];
    backgroundWindow = [[BlackWindow alloc] init];
    [NoirController setController:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedWindow:) name:@"NSWindowDidBecomeMainNotification" object:nil];
    antiSleepTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(preventSleep:) userInfo:nil repeats:YES];
    NSApp.delegate = self;
}

-(void)dealloc
{
    [mouseMoveTimer invalidate];
    [antiSleepTimer invalidate];
    [lastCursorMoveDate release];
    [super dealloc];
}

-(NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)openableFileExtensions
{
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    return [super runModalOpenPanel:openPanel forTypes:@[@"avi", @"mov", @"qt", @"mpg", @"mpeg", @"m15", @"m75", @"m2v", @"3gpp", @"mpg4", @"mp4", @"mkv", @"flv", @"divx", @"m4v", @"swf", @"fli", @"flc", @"dv", @"wmv", @"asf", @"ogg",
        // Finder types
        @"VfW", @"MooV", @"MPEG", @"m2v ", @"mpg4", @"SWFL", @"FLI ", @"dvc!", @"ASF_"]];
}

-(void)checkMouseLocation:(id)sender
{
    NSRect tempRect =[NSScreen screens][0].frame;
    NSPoint tempPoint =[NSEvent mouseLocation];
    if(!NSEqualPoints(lastMouseLocation, tempPoint)) {
        [lastCursorMoveDate release];
        lastCursorMoveDate = [[NSDate alloc] init];
        lastMouseLocation= tempPoint;
        [NSCursor setHiddenUntilMouseMoves:NO];
    } else {
        if(fullScreenMode && lastCursorMoveDate.timeIntervalSinceNow < -3) [NSCursor setHiddenUntilMouseMoves:YES];
    }
    
    tempRect.origin.y=tempRect.size.height -24;
    tempRect.size.height =32;
}

/* As per Technical Q&A QA1160: http://developer.apple.com/qa/qa2004/qa1160.html */
-(void)preventSleep:(id)sender
{
    NSEnumerator *enumerator = [NSApp.orderedDocuments objectEnumerator];
    id each;
    while((each = [enumerator nextObject])) {
        if(![each isPlaying]) continue;
        UpdateSystemActivity(OverallAct);
        return;
    }
}

-(id)mainDocument
{
    return [self documentForWindow:NSApp.mainWindow];
}

-(void)changedWindow:(NSNotification *)notification
{
}

#pragma mark -
#pragma mark Interface

-(IBAction)openDocument:(id)sender
{
    NSArray *files = [self URLsFromRunningOpenPanel];
    for(unsigned i = 0; i < files.count; i++) {
        NSError* tError = nil;
        id url = files[i];
        [self openDocumentWithContentsOfURL:url display:YES error:&tError];
        if(tError) [NSApp presentError:tError];
    }
    if(!NSApp.mainWindow) NSLog(@"no main window");
    if(files.count) [[self mainDocument] playMovie];
}

-(IBAction)toggleFullScreen:(id)sender
{
    if(fullScreenMode) {
        [self exitFullScreen];
    } else if([NSApp.mainWindow isKindOfClass:[NoirWindow self]]) {
        [self enterFullScreen];
    }
}

#pragma mark -
#pragma mark Presentation

-(void)presentScreen
{
    id screen = [NSScreen mainScreen];
    fullScreenMode = YES;
    if([screen isEqualTo:[NSScreen screens][0]]) NSApp.presentationOptions = NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar;
    [backgroundWindow setFrame:[screen frame] display:YES];
    [backgroundWindow orderBack:nil];
}

-(BOOL)isFullScreen
{
	return fullScreenMode;
}

-(void)unpresentScreen
{
    fullScreenMode = NO;
    NSApp.presentationOptions = NSApplicationPresentationDefault;
    [backgroundWindow orderOut:nil];
}

-(void)enterFullScreen
{
    id tempWindow = NSApp.mainWindow;
    [tempWindow makeFullScreen];
    [self presentScreen];
    [backgroundWindow setPresentingWindow:tempWindow];
}

-(void)exitFullScreen
{
    id tempWindow = NSApp.mainWindow;
    if(tempWindow) [tempWindow makeNormalScreen];
    [self unpresentScreen];
}

#pragma mark -
#pragma mark Accessor Methods

-(id)backgroundWindow
{
    return backgroundWindow;
}

-(IBAction)dummyMethod:(id)temp
{
}

@end

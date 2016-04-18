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
* Jay Tuley & Robert Chin.
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

#import "NoirController.h"
#import "NPApplication.h"
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
    [NSApp setDelegate:self];
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
    return [super runModalOpenPanel:openPanel forTypes:[NSArray arrayWithObjects:
        // File extensions
        @"avi", @"mov", @"qt", @"mpg", @"mpeg", @"m15", @"m75", @"m2v", @"3gpp", @"mpg4", @"mp4", @"mkv", @"flv", @"divx", @"m4v", @"swf", @"fli", @"flc", @"dv", @"wmv", @"asf", @"ogg",
        // Finder types
        @"VfW", @"MooV", @"MPEG", @"m2v ", @"mpg4", @"SWFL", @"FLI ", @"dvc!", @"ASF_", nil]];
}

-(void)checkMouseLocation:(id)sender
{
    NSRect tempRect =[[[NSScreen screens] objectAtIndex:0] frame];
    NSPoint tempPoint =[NSEvent mouseLocation];
    if(!NSEqualPoints(lastMouseLocation, tempPoint)) {
        [lastCursorMoveDate release];
        lastCursorMoveDate = [[NSDate alloc] init];
        lastMouseLocation= tempPoint;
        [NSCursor setHiddenUntilMouseMoves:NO];
    } else {
        if(fullScreenMode && [lastCursorMoveDate timeIntervalSinceNow] < -3) [NSCursor setHiddenUntilMouseMoves:YES];
    }
    
    tempRect.origin.y=tempRect.size.height -24;
    tempRect.size.height =32;
}

/* As per Technical Q&A QA1160: http://developer.apple.com/qa/qa2004/qa1160.html */
-(void)preventSleep:(id)sender
{
    NSEnumerator *enumerator = [[NSApp orderedDocuments] objectEnumerator];
    id each;
    while((each = [enumerator nextObject])) {
        if(![each isPlaying]) continue;
        UpdateSystemActivity(OverallAct);
        return;
    }
}

-(id)mainDocument
{
    return [self documentForWindow:[NSApp mainWindow]];
}

-(void)changedWindow:(NSNotification *)notification
{
}

#pragma mark -
#pragma mark Interface

-(IBAction)openDocument:(id)sender
{
    NSArray *files = [self URLsFromRunningOpenPanel];
    for(unsigned i = 0; i < [files count]; i++) {
        NSError* tError = nil;
        id url = [files objectAtIndex:i];
        [self openDocumentWithContentsOfURL:url display:YES error:&tError];
        if(tError) [NSApp presentError:tError];
    }
    if(![NSApp mainWindow]) NSLog(@"no main window");
    if([files count]) [[self mainDocument] playMovie];
}

-(IBAction)toggleFullScreen:(id)sender
{
    if(fullScreenMode) {
        [self exitFullScreen];
    } else if([[NSApp mainWindow] isKindOfClass:[NoirWindow self]]) {
        [self enterFullScreen];
    }
}

#pragma mark -
#pragma mark Presentation

-(void)presentScreen
{
    id screen = [NSScreen mainScreen];
    fullScreenMode = YES;
    if([screen isEqualTo:[[NSScreen screens] objectAtIndex:0]]) SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
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
    SetSystemUIMode(kUIModeNormal, kUIModeNormal);
    [backgroundWindow orderOut:nil];
}

-(void)enterFullScreen
{
    id tempWindow = [NSApp mainWindow];
    [tempWindow makeFullScreen];
    [self presentScreen];
    [backgroundWindow setPresentingWindow:tempWindow];
}

-(void)exitFullScreen
{
    id tempWindow = [NSApp mainWindow];
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

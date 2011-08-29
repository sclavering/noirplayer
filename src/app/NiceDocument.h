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



#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "NPMovieView.h"
#import "NiceWindow.h"

@class NiceWindow;
@class NPMovieView;

enum PreStepingStates { PSS_INACTIVE, PSS_STOPPED, PSS_PLAYING };

@interface NiceDocument : NSDocument
{
    IBOutlet NPMovieView *theMovieView;
    IBOutlet NiceWindow *theWindow;
    NSMutableArray *menuObjects;
    BOOL wasPlayingBeforeMini;
    QTMovie* movie;
    enum PreStepingStates preSteppingState;
}

-(NSData *)dataRepresentationOfType:(NSString *)aType;

#pragma mark Window Information

-(void)windowDidDeminiaturize:(NSNotification *)aNotification;
-(void)windowControllerDidLoadNib:(NSWindowController *) aController;
-(NSMenu *)movieMenu;
-(void)rebuildMenu;
-(id)window;
-(NSMenuItem*)volumeMenu;

#pragma mark Play/Pause

-(BOOL)isPlaying;
-(void)togglePlayingMovie;
-(void)playMovie;
-(void)pauseMovie;

#pragma mark Stepping

-(void)startStepping;
-(void)stepBy:(int)aSeconds;
-(void)endStepping;

#pragma mark Time

-(double)totalTime;
-(double)currentMovieTime;
-(void)setCurrentMovieTime:(double)aDouble;
-(double)currentTimeAsFraction;
-(void)setMovieTimeByFraction:(double)when;

#pragma mark Volume

-(IBAction)switchVolume:(NSMenuItem*)sender;
-(IBAction)increaseVolume:(id)sender;
-(IBAction)decreaseVolume:(id)sender;

-(float)volume;
-(void)setVolume:(float)aVolume;
-(void)incrementVolume;
-(void)decrementVolume;

@end

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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@class ControlPlay;
@class NiceWindow;

enum play_states { STATE_INACTIVE, STATE_STOPPED, STATE_PLAYING };

@interface NPMovieView : NSView {
    QTMovie* movie;
    QTMovieView* qtview;
    id contextMenu;
	float internalVolume;
    NSTrackingRectTag trackingRect;
    enum play_states oldPlayState;
    BOOL mouseEntered;
}

+(NSArray *)supportedFileExtensions;

-(void)openMovie:(QTMovie*)movie;
-(void)close;

-(void)mouseDoubleClick:(NSEvent *)anEvent;

-(void)start;
-(void)stop;

-(void)incrementVolume;
-(void)decrementVolume;
-(void)setVolume:(float)aVolume;
-(float)volume;

-(BOOL)isPlaying;

-(void)showOverLayVolume;
-(void)smartHideMouseOverOverlays;
-(void)timedHideVolumeOverlay;

-(id)myMenu;
-(id)pluginMenu;
-(NSMenu*)audioTrackMenu;
-(NSMenu*)videoTrackMenu;
-(id)contextualMenu;
-(void)rebuildMenu;

-(void)scrollWheelResize:(float)delta;

-(double)scrubLocation:(id)sender;
-(NSSize)naturalSize;
-(double)percentLoaded;
-(void)drawMovieFrame;

-(double)totalTime;
-(double)currentMovieTime;
-(void)setCurrentMovieTime:(double)aDouble;
-(BOOL)hasEnded:(id)sender;

-(void)startStepping;
-(void)stepBy:(int)aSeconds;
-(void)endStepping;

@end

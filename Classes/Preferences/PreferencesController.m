/**
 * PreferencesController.m
 * NicePlayer
 *
 * The preferences controller allowing the preferences GUI to interact with the preference
 * cache and the NSUserDefaults system.
 */

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

#import "PreferencesController.h"
#import "NPApplication.h"
#import "NiceUtilities.h"
#import <Preferable/Preferable.h>

@implementation PreferencesController

-(void)awakeFromNib
{
    id tempBundle =[NSBundle bundleForClass:[PFPreferenceModule self]];
    
    NSString* tGeneralPrefIcon = [tempBundle pathForResource:@"GeneralPreferenceIcon" ofType:@"png"];
    NSString* tActionPrefIcon =[tempBundle pathForResource:@"ActionsPreferenceIcon" ofType:@"png"];

	[prefWindowController addPane:paneMain
                   withIcon:[[[NSImage alloc]initWithContentsOfFile:tGeneralPrefIcon] autorelease]
		 withIdentifier:@"General"
			  withLabel:@"General"
			withToolTip:@"The General Preference Settings"
		 allowingResize:NO];
	[prefWindowController addPane:paneWindowDefaults
                   withIcon:[NSImage imageNamed:@"windpref"] 
		 withIdentifier:@"Window Defaults"
			  withLabel:@"Window Defaults"
			withToolTip:@"The Window Default Preference Settings"
		 allowingResize:NO];
	
	[scrollResizePin selectItemAtIndex:[[Preferences mainPrefs] scrollResizePin]];
	[defaultTimeDisplay selectItemAtIndex:[[Preferences mainPrefs] defaultTimeDisplay]];

        id aDate = [NSDate dateWithTimeIntervalSinceReferenceDate:
            ([[Preferences mainPrefs] rrSpeed]- [[NSTimeZone localTimeZone] secondsFromGMTForDate:
                [NSDate dateWithTimeIntervalSinceReferenceDate:0]])];
        [rrSpeedSlider setObjectValue:aDate];

               
        id aDate2 = [NSDate dateWithTimeIntervalSinceReferenceDate:
            ([[Preferences mainPrefs] ffSpeed]- [[NSTimeZone localTimeZone] secondsFromGMTForDate:
                [NSDate dateWithTimeIntervalSinceReferenceDate:0]])];
        [ffSpeedSlider setObjectValue:aDate2];

	[windowAlwaysOnTop setState:[[Preferences mainPrefs] windowAlwaysOnTop]];
	[opacityWhenWindowIsTransparent setFloatValue:[[Preferences mainPrefs] opacityWhenWindowIsTransparent]];
}

-(IBAction)scrollResizePin:(id)sender
{
	[[Preferences mainPrefs] setScrollResizePin:[sender indexOfSelectedItem]];
}

-(IBAction)defaultTimeDisplay:(id)sender
{
	[[Preferences mainPrefs] setDefaultTimeDisplay:[sender indexOfSelectedItem]];
}

#pragma mark -

-(IBAction)rrSpeed:(id)sender
{
    //[[Preferences mainPrefs] setRrSpeed:[sender intValue]];

   // id date =[NSCalendarDate dateWithString:[sender stringValue] calendarFormat:@"%H:%M:%S"];
    
    int total = [[sender objectValue] secondOfMinute];
    total += 60 * [[sender objectValue] minuteOfHour];
     total += 60* 60* [[sender objectValue] hourOfDay];
    [[Preferences mainPrefs] setRrSpeed:total];
}

-(IBAction)ffSpeed:(id)sender
{
   // [[Preferences mainPrefs] setFfSpeed:[sender intValue]];
    //id date =[NSCalendarDate dateWithString:[sender stringValue] calendarFormat:@"%H:%M:%S"];
    int total = [[sender objectValue] secondOfMinute];
    total += 60 * [[sender objectValue] minuteOfHour];
    total += 60* 60* [[sender objectValue] hourOfDay];
    [[Preferences mainPrefs] setFfSpeed:total];
}

#pragma mark -

-(IBAction)windowAlwaysOnTop:(id)sender
{
	[[Preferences mainPrefs] setWindowAlwaysOnTop:[sender state]];
}

-(IBAction)opacityWhenWindowIsTransparent:(id)sender
{
	[[Preferences mainPrefs] setOpacityWhenWindowIsTransparent:[sender floatValue]];
}

@end

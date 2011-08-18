/**
 * Preferences.m
 * NicePlayer
 *
 * The preferences cache for the application.
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

#import "Preferences.h"
#import "NPApplication.h"

@implementation Preferences

+ (void)initialize
{	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:0.5], @"opacityWhenWindowIsTransparent",
		nil];
	
    [defaults registerDefaults:appDefaults];
}

+(Preferences *)mainPrefs
{
        static Preferences * prefs = nil;
	if(prefs == nil)
		prefs = [Preferences new];
	return prefs;
}

+(int)defaultTimeDisplayValuesNum;
{
	return 2;
}

-(id)init
{
	if((self = [super init])){
		defaultTimeDisplay = [[NSUserDefaults standardUserDefaults] integerForKey:@"defaultTimeDisplay"];
		opacityWhenWindowIsTransparent = [[NSUserDefaults standardUserDefaults] floatForKey:@"opacityWhenWindowIsTransparent"];
	}
	return self;
}

-(void)setWindowPosition:(NSPoint) aPoint
{
	[[NSUserDefaults standardUserDefaults] setObject:NSStringFromPoint(aPoint) forKey:@"windowOrigin"];
}

-(NSString*)windowPosition
{
	return [[NSUserDefaults standardUserDefaults] valueForKey:@"windowOrigin"];
}

-(enum defaultTimeDisplayValues)defaultTimeDisplay
{
	return defaultTimeDisplay;
}

-(void)setDefaultTimeDisplay:(enum defaultTimeDisplayValues)anInt
{
	defaultTimeDisplay = anInt;
	[[NSUserDefaults standardUserDefaults] setInteger:anInt forKey:@"defaultTimeDisplay"];
}

#pragma mark -

-(float)opacityWhenWindowIsTransparent
{
	return opacityWhenWindowIsTransparent;
}

-(void)setOpacityWhenWindowIsTransparent:(float)aFloat
{
	[self willChangeValueForKey:@"opacityWhenWindowIsTransparent"];
	opacityWhenWindowIsTransparent = aFloat;
	[[NSUserDefaults standardUserDefaults] setFloat:aFloat forKey:@"opacityWhenWindowIsTransparent"];
	[self didChangeValueForKey:@"opacityWhenWindowIsTransparent"];
}

@end

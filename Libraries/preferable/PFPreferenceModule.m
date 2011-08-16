//
//  PFPreferenceModule.m
//  Preferable
//
//  Created by James Tuley on 5/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

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
 * The Original Code is Preferable.
 *
 * The Initial Developer of the Original Code is
 * James Tuley.
 * Portions created by the Initial Developer are Copyright (C) 2004-2008
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *           James Tuley <jay+preferable@tuley.name> (NicePlayer Author)
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

#import "PFPreferenceModule.h"


@implementation PFPreferenceModule

+(PFPreferenceModule*)moduleWithToolbarItem:(NSToolbarItem*)anItem andView:(NSView*)aView andResizable:(bool) anIsResizable{
	PFPreferenceModule* tModule = [[self alloc]init];
	[tModule setToolbarItem:anItem];
	[tModule setView:aView];
	[tModule setResizable:anIsResizable];
	return [tModule autorelease];
}


-(NSToolbarItem*)toolbarItem{
	return mToolbarItem;
}
-(void)setToolbarItem:(NSToolbarItem*)anItem{
	[mToolbarItem release];
	mToolbarItem = [anItem retain];
}

-(NSView*)view{
	return mView;
}
-(void)setView:(NSView*)aView{
	[mView release];
	mView = [aView retain];
}

-(NSBundle*)bundle{
	return mBundle;
}
-(void)setBundle:(NSBundle*)aBundle{
	[mBundle release];
	mBundle =[aBundle retain];
}

-(NSString*)nibName{
	return mNibName;
}
-(void)setNibName:(NSString*)aName{
	mNibName =aName;
}

-(bool)resizeable{
	return mResizable;
}
-(void)setResizable:(bool)aResizable{
	mResizable =aResizable;
}


@end

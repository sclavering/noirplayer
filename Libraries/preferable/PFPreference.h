//
//  PFPreference.h
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




#import <Cocoa/Cocoa.h>


@class PFPreferenceModule;

@interface PFPreference : NSObject {
	@public
	IBOutlet NSWindow* window;

    @private
	NSMutableDictionary* mModuleDictionary;
    NSMutableArray* mToolbarOrder;
    NSString* mSuffix;
    NSString* mPrefix;
	NSView* mBlankView;
    id mReserved;
    id mReserved2;
    id mReserved3;
    id mReserved4;
}


-(IBAction)showWindow:(id)aSender;
-(IBAction)showModule:(id)aSender;

-(void)showModuleWithIdentifier:(NSString*)anIdentifier;

-(NSWindow*)window;
-(void)setWindow:(NSWindow*)aWindow;


-(void)setTitleSuffix:(NSString*)aSuffix;
-(NSString*)titleSuffix;

-(void)setTitlePrefix:(NSString*)aPrefix;
-(NSString*)titlePrefix;

-(void)addPane:(NSView*)aView 
      withIcon:(NSImage*)anImage
withIdentifier:(NSString*)anIdentifier
     withLabel:(NSString*)aLabel
   withToolTip:(NSString*)aToolTip
allowingResize:(BOOL)allowResize;

-(void)addPane:(PFPreferenceModule*)aModule;

-(NSToolbarItem*)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;

-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;

@end

//
//  PFPreferenceWindowController.m
//  Preferable
//
//  Created by James Tuley on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
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

#import "PFPreferenceWindowController.h"
#import "PFPreferenceModule.h"



@interface PFPreferenceWindowController(Private) 
-(void)_PFshowPaneWithView:(NSView*)aNewView andResetWidth:(BOOL)aWidthReset;
-(float) _PFToolbarHeightForWindow;
- (float) _PFTitleBarHeight;
@end

@implementation PFPreferenceWindowController

- (id)initWithWindowNibName:(NSString*)aString{
	if(self = [super initWithWindowNibName:aString]){
	 mModuleDictionary =[[NSMutableDictionary alloc]init];
    mToolbarOrder =[[NSMutableArray alloc]init];
	mSuffix  =@"";
	mPrefix=@"";
		mBlankView=[[NSView alloc]init];
		mChangingView=NO;
	}return self;
}
-(void)PF_lazyToolbarInitialize{
	if([[self window] toolbar]==nil){
		// NSLog(@"Initialize for first time");
        NSToolbar* tempToolbar =[[NSToolbar alloc]initWithIdentifier:@"Preferences Toolbar"];
        [tempToolbar setDelegate:self];
		[[self window] setDelegate:self];
        [[self window] setToolbar:tempToolbar]; 
        [self showModuleWithIdentifier:[mToolbarOrder objectAtIndex:0]];
        [tempToolbar validateVisibleItems];

    }
}



-(IBAction)showWindow:(id)aSender{
	[self PF_lazyToolbarInitialize];
	[super showWindow:aSender];
}
-(void)showModule:(id)sender{
	[self showModuleWithIdentifier:[sender itemIdentifier]];	
}


-(void)showModuleWithIdentifier:(NSString*)anIdentifier{
	
	PFPreferenceModule* tModule = [mModuleDictionary objectForKey:anIdentifier];
	
	//if(![[[[self window] toolbar] selectedItemIdentifier] isEqualTo:anIdentifier]){
		
        [[[self window] toolbar] setSelectedItemIdentifier:anIdentifier];
        [[self window] setTitle:[NSString stringWithFormat:@"%@ %@ %@",[self titlePrefix],[[tModule toolbarItem] label],[self titleSuffix],nil]];
		
	mChangingView=YES;
		[self _PFshowPaneWithView:[tModule view] andResetWidth:[tModule resizeable]];
	mChangingView=NO;
        
        [[self window] setShowsResizeIndicator:[tModule resizeable]];
        [[[self window] standardWindowButton:NSWindowZoomButton] setEnabled:[tModule resizeable]];
		if(![tModule resizeable]){
			
		}
        
		
   // }
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize{
	
	if([[mModuleDictionary objectForKey:[[[self window] toolbar] selectedItemIdentifier]] resizeable] ||  mChangingView){
		return proposedFrameSize;
	}else{
		return [window frame].size;
	}
		
}

-(void)_PFshowPaneWithView:(NSView*)aNewView andResetWidth:(BOOL)aWidthReset{
    float newHeight =(([aNewView bounds]).size.height) + [self _PFToolbarHeightForWindow];
    float newWidth;
    NSRect myWinFrame =[[self window] frame];
    if(aWidthReset)
        newWidth = [[self window] minSize].width;
    else
        newWidth = myWinFrame.size.width;
    NSRect newFrame=NSMakeRect(myWinFrame.origin.x,myWinFrame.origin.y-(newHeight- myWinFrame.size.height),newWidth,newHeight);
    [[self window] setContentView:mBlankView];
    [[self window] setFrame:newFrame display:YES animate:YES];
    [[self window] setContentView:aNewView];
}

- (float) _PFTitleBarHeight
{
    NSRect frame = NSMakeRect (0, 0, 100, 100);
	
    NSRect contentRect;
    contentRect = [NSWindow contentRectForFrameRect: frame
										  styleMask: NSTitledWindowMask];
	
    return (frame.size.height - contentRect.size.height);
	
} 

-(float) _PFToolbarHeightForWindow
{
    NSToolbar *toolbar;
    float tToolbarHeight = 0.0;
    NSRect tWindowFrame;
	
    toolbar = [[self window] toolbar];
	
    if(toolbar && [toolbar isVisible])
    {
        tWindowFrame = [NSWindow contentRectForFrameRect:[[self window] frame]
											   styleMask:[[self window] styleMask]];
        tToolbarHeight = NSHeight(tWindowFrame)
		- NSHeight([[[self window] contentView] frame]);
    }
	
    return tToolbarHeight+[self _PFTitleBarHeight];
}

-(void)setTitleSuffix:(NSString*)aSuffix{
	mSuffix =aSuffix;
}
-(NSString*)titleSuffix{
	return mSuffix;
}
-(void)setTitlePrefix:(NSString*)aPrefix{
	mPrefix = aPrefix;
}
-(NSString*)titlePrefix{
	return mPrefix;
}

-(void)addPane:(NSView*)aView 
      withIcon:(NSImage*)anImage
withIdentifier:(NSString*)anIdentifier
     withLabel:(NSString*)aLabel
   withToolTip:(NSString*)aToolTip
allowingResize:(BOOL)allowResize{
	NSToolbarItem* tItem = [[[NSToolbarItem alloc ]initWithItemIdentifier:anIdentifier]autorelease];
	[tItem  setToolTip:aToolTip];
	[tItem setLabel:aLabel];
	[tItem setImage:anImage];
	[tItem setAction:@selector(showModule:)];
	[tItem setTarget:self];
	
	[self addPane:[PFPreferenceModule moduleWithToolbarItem:tItem  andView:aView andResizable:allowResize]];
}
-(void)addPane:(PFPreferenceModule*)aModule{
	NSToolbarItem* tItem = [aModule toolbarItem];
	[tItem setTarget:self];
	[tItem setAction:@selector(showModule:)];
	
	[mModuleDictionary setObject:aModule forKey:[[aModule toolbarItem] itemIdentifier]];
	[mToolbarOrder addObject:[[aModule toolbarItem] itemIdentifier]];
}


-(NSToolbarItem*)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag{
    return [[mModuleDictionary objectForKey:itemIdentifier] toolbarItem];
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)aToolbar{
    
    return mToolbarOrder; 
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)aToolbar{
    return mToolbarOrder;    
}

-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)aToolbar{
    return mToolbarOrder; 
    
}


@end

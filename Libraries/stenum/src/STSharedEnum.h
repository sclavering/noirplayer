
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
* The Original Code is STEnum.
*
* The Initial Developer of the Original Code is
* James Tuley.
* Portions created by the Initial Developer are Copyright (C) 2004-2005
* the Initial Developer. All Rights Reserved.
*
* Contributor(s):
*           James Tuley <jbtule@mac.com> (Original Author)
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

//
//  STSharedEnum.h
//  STEnum
//
//  Created by James Tuley on 4/2/05.
//  Copyright 2005 James Tuley. All rights reserved.
//

/*!
@header NSArray_NSSet_NSDictionary(STSharedCollectionAdditions)
 @abstract    Methods that are added to all of the main collection classes
 @discussion  These methods should work on NSArrays, NSDictionarys, NSSets and their subclasses.
 @copyright James Tuley

 */

    /*!
    @method     doUsingFunction:context:
     @abstract   Runs the doFunction on very element in the collection in enumeration order.
     @param      doFunction read more at @link //apple_ref/c/tdef/STDoFunction STDoFunction @/link
     @param      context This context pointer allows you to pass in extra contextual objects (useful when using static functions)
     */

-(void)doUsingFunction:(STDoFunction)doFunction
               context:(void *)context;

    /*!
    @method     selectUsingFunction:context:
     @abstract   Selects all objects in which the selectingFunction returns true.
     @discussion (comprehensive description)
     @param      selectingFunction read more at @link //apple_ref/c/tdef/STSelectFunction STSelectFunction @/link
     @param      context This context pointer allows you to pass in extra contextual objects (useful when using static functions)
     */

-(id)selectUsingFunction:(STSelectFunction)selectingFunction
                 context:(void *)context;

    /*!
    @method     rejectUsingFunction:context:
     @abstract  Rejects all objects in which the rejectingFunction returns true.
     @discussion (comprehensive description)
     @param      rejectingFunction read more at @link //apple_ref/c/tdef/STSelectFunction STSelectFunction @/link
     @param      context This context pointer allows you to pass in extra contextual objects (useful when using static functions)
     */
-(id)rejectUsingFunction:(STSelectFunction)rejectingFunction
                 context:(void *)context;

    /*!
    @method     detectUsingFunction:context:
     @abstract   Detects the first element in which the detectingFunction returns true.
     @discussion (comprehensive description)
     @param      detectingFunction read more at @link //apple_ref/c/tdef/STSelectFunction STSelectFunction @/link
     @param      context This context pointer allows you to pass in extra contextual objects (useful when using static functions)
     */
-(id)detectUsingFunction:(STSelectFunction)detectingFunction
                 context:(void *)context;

# Bunjee TODO

## Interface improvements

* Upon saving a case, query which scenes should be saved with them among the scenes that contain data display items bound to at least one data item belonging to that case
*
* Implement better heuristics when loading a scene (scene must be displayed in view if 1 view mode), or switching layout (scene association must be preserved when increasing or decreasing layout views)
* Better default W/L
* Better default zoom when going 2D. Store it somewhere.
*
* When create case from series, add filtering options upon loading (as NSOpenPanel accessory view).
*
* Display editor defaults must be settable at the scene level, and at the application level. Add button in display editor with popup (save for scene, save for all). 
*
* There should be a persistent feedback somewhere on what image is active (in scene annotations in the rendering window or beside the scene dropdown in the panel).
*
* Fix scene renaming, implement item renaming (now easier since names are not keys)
*
* Button for flipping with respect to default in slice mode
*
* Add visual clue that there's more in the outline view when data type filter is on
*
* Scene view: sort by case (Scene1|Case 1-data |Case 2-data) and remove string for the path
*
* Enhance scene-wide properties, e.g. name, eventually comment, list of display items (editable?), list of cases. 
*
* All cases (DB) view
*
* Enhance case info when only one data item is displayed (basic parameters (number of points, etc), advanced parameters). Or, better: segmented control with DataInfo, Geometry, Advanced etc that activates the "richness" of the information.
*
* For each scene, store layout and position of 3D camera in each layout (and for each slice view?) in plist
*
* Implement synchronized crosshair (now possible through crosshair notification!!!!)
*
* Display properties: apply to all data types in scene; apply to all centerlines; make default
*
* Implement image orientation
* Fix fullscreen mode
*
* Change save URL when scene template checkbox is toggled upon saving (otherwise hard to find a name for a template)
*
* Handle application-wide user defaults, including **paths** (now hard coded to AriX in Bunjee!)

## OsiriX plugin

Todo

## Seed on MIP (pre-generate simple MIPS on plane views)
* The line on MIP functionality could be implemented by tracing two lines in two different MIPS (or in the same MIP at two different times), rather than one line on one MIP and then trying to infer (which would probably work anyway, for ARIC for example). The intersection between the projected planes is the line of interest. Similarly, the seed on MIP could be implemented by placing a point on one MIP, casing a line in the other views and seeding the second point on top of that line.


# HorrorScope 
**On the Fly Cameras Plugin For Classic Quake Mods**  
version 1.1


This repo contains a compact plugin version of HorrorScope on the fly cameras, as well as camera files and examples.
The main plugin file for HorrorScope 'hrscope-plugin.qc' defines functions for finding a camera position, casting 
the players view, returing the player to their original position, handling button pressess, etc. 
The plugin file contains one basic camera function 'camera_default()'.  See /cameras and /examples for more cameras.

Download the complete HorrorScope package which contains plugin, cameras presets, examples, and a demo mod:  
https://www.slipseer.com/horrorscope

Video demos of Horrorscope:  
https://www.youtube.com/@matboe
    
Tested with Quakespasm, QSS, Ironwail



### To install
1. Copy 'hrscope-plugin.qc' to your mod source code directory alongside 'weapons.qc'

2. Add lines to the top of player_posthink() in 'client.qc'
```
hr_frame();    		//HorrorScope	 
if (self.cam)
  return;
```

3. Add line to 'progs.src' above 'combat.qc'.  Also add any camera_*.qc files here
```
hrscope-plugin.qc  //HorrorScope
cameras/camera_example1.qc  //HorrorScope
combat.qc  
```

4. Open or create 'autoexec.cfg' in your mod folder and add line  
```
sv_protocol 999
```

5. Compile with [FTEQCC](https://fte.triptohell.info/downloads)


### Concept
I wanted a system for easily moving the players view to another entity and back again on demand.
I can imagine this plugin might be used to create in-game cutscenes and for making interesting demos or trailers.


### Changes v1.1
* Improved method for adjusting camera angles to keep target centered.  Camera rotation is now done by setting .avelocity
  instead assigning discreet angles every frame.  This makes playing over a network far more reliable.
* Refined and simplified codebase, corrected minor errors and formatting, added more comments.

# HorrorScope  
**On the Fly Cameras Plugin For Classic Quake Mods**

This is a compact plugin version of HorrorScope Cameras Mod condensed into one .qc file and is designed to be simple to drop 
into an existing mod to implement TV style cameras.
There is only one baisc camera included with this condensed version, however you can directly copy & paste code from the cameras and examples section in this repo.
 
Tested with Quakespasm, QSS, Ironwail

### To install
1. Copy 'hrscope-plugin.qc' to your mod source code directory alongside 'weapons.qc'

2. Add lines to the top of player_posthink() in 'client.qc'
```
hr_frame();    		//HorrorScope	 
if (self.cam)
  return;
```

3. Add line to 'progs.src' above 'combat.qc'
```
hrscope-plugin.qc  //HorrorScope
combat.qc  
```

4. Create 'autoexec.cfg' in your mod folder and add line  
```
sv_protocol 999
```

5. Compile with [FTEQCC](https://fte.triptohell.info/downloads)


### Concept
I wanted a system for easily moving the players view to another entity and back again on demand.
I can imagine this plugin might be used to create in-game cutscenes and for making interesting demos or trailers.


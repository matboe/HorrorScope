# HorrorScope  
**ON THE FLY CAMERAS MOD FOR CLASSIC QUAKE**

This is a compact plugin version that is condensed into one .qc file and is designed to be simple to drop 
into an existing mod to implement TV style cameras.
 
Tested with Quakespasm, QSS, Ironwail

[![Watch the video](https://img.youtube.com/vi/Wg8G70uxyKc/maxresdefault.jpg)](https://youtu.be/_XbwMK3EdVc)

### To install
1. Copy 'hrscope-plugin.qc' to your mod source code directory alongside 'weapons.qc'

2. Add lines to the top of player_posthink() in 'client.qc'
```
hr_frame();    		//HorrorScope	 
if (self.cam)
  return;
```

3. Add line to 'progs.src' above 'client.qc'
```
hrscope-plugin.qc  //HorrorScope
client.qc  
```

4. Create 'autoexec.cfg' in your mod folder and add line  
```
sv_protocol 999
```

5. Compile with [FTEQCC](https://fte.triptohell.info/downloads)



### Concept
I wanted a system for easily moving the players view to another entity and back again on demand.
I can imagine this plugin might be used to create in-game cutscenes and for making interesting demos or trailers.


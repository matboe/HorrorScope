/* hrscope-plugin.qc
 ===============================================================                                                                                      

   ░▒█░▒█░▄▀▀▄░█▀▀▄░█▀▀▄░▄▀▀▄░█▀▀▄░▒█▀▀▀█░█▀▄░▄▀▀▄░▄▀▀▄░█▀▀
   ░▒█▀▀█░█░░█░█▄▄▀░█▄▄▀░█░░█░█▄▄▀░░▀▀▀▄▄░█░░░█░░█░█▄▄█░█▀▀
   ░▒█░▒█░░▀▀░░▀░▀▀░▀░▀▀░░▀▀░░▀░▀▀░▒█▄▄▄█░▀▀▀░░▀▀░░█░░░░▀▀▀
	- On the fly cameras plugin for Quake mods -

 =====================================- by Matboe 2023 -========

 [INSTALLATION]

  1) Copy 'hrscope-plugin.qc' to your mod source code directory
     alongside 'weapons.qc'


  2) Add line to 'progs.src' above 'combat.qc'
     --------------------------------------
       hrscope-plugin.qc	//HorrorScope
     --------------------------------------


  3) Add lines to the top of player_posthink() in 'client.qc'
     --------------------------------------
       hr_frame();    		//HorrorScope	
       if (self.cam)
         return;
     --------------------------------------


  4) Create or open 'autoexec.cfg' in your mod folder and add line:
     --------------------------------------
       sv_protocol 999
     --------------------------------------


  5) Compile 'progs.dat'  
     Recommend FTEqcc (https://fte.triptohell.info/downloads)


 <NOTES>
  -To execute HorrorScope funciton call 'HorrorScope (camera_name)'.
  For example:
 
  if (self.impule == 100)
	HorrorScope (camera_example1);

  HorroScope will run camera_default if none is specified.


  -You must specify .aiment! A cameras .aiment is its target 
  entity, what it will aim at.
  For example to aim at a Grunt:

  self.aiment = find (world, classname, "monster_army");
 

  -This is the condensed plugin version of HorrorScope.
  Download the complete package with further instructions
  and camera examples from:
  https://www.slipseer.com/horrorscope

=============================================================*/

//global constants
float HR_MAX_CAM_DIST	= 1024;		// maximum distance to spawn a camera position
float HR_MIN_CAM_DIST 	= 256;		// maximum distance to spawn a camera position
float hr_print_info	= 1;		// print cam info on/off
float SVC_SETVIEWPORT 	= 5;
float SVC_SETVIEWANGLES = 10;

//entity fields
.float shot_time;			// time until shot expires
.float last_y_speed;			// store angle movement amount to reference in next frame
.float last_x_speed;
.float hr_button_time;			// time between button presses
.vector hr_oldangles;			// store players angles 
.vector hr_oldorigin;			// store players origin
.entity cam;				// players camera entity

//function prototypes
void() camera_default;
void(void() run_cam) HorrorScope;
void() Exit_HorrorScope;
void(string str) hr_print;
void() hr_frame;
void() W_SetCurrentAmmo;
float(vector org) hr_visible;
float(entity targ) hr_infront;
float() crandom;

//================================ SET CAMERA / PLAYER VIEW ================================

//===================
// set view to camera
//===================
void() hr_SetViewPort_Cam =
{
	msg_entity = self;	
	WriteByte (MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity (MSG_ONE, self.cam);
	WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
	WriteAngle (MSG_ONE, self.cam.angles_x);
	WriteAngle (MSG_ONE, self.cam.angles_y);
	WriteAngle (MSG_ONE, self.cam.angles_z);
};

//===================
// set view to player
//===================
void() hr_SetViewPort_Player =
{
	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity (MSG_ONE, self);
	WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
	WriteAngle (MSG_ONE, self.angles_x);
	WriteAngle (MSG_ONE, self.angles_y);
	WriteAngle (MSG_ONE, self.angles_z);
};


//====================================================
// check player impulses and button press every frame
//====================================================
void() hr_frame =
{
	//check impulses
	if (self.impulse == 100)
	{
		//toggle start/stop HorrorScope
		if (self.cam)
		{
			Exit_HorrorScope();
			self.impulse = 0;
			return;
		}			
		else
		{
			//store players origin/angles
			self.hr_oldangles = self.angles;
			self.hr_oldorigin = self.origin;

			//start HorrorScope			
			HorrorScope (camera_default);
		}
	}

	//check button press
	if (self.cam)
	{
		//exit on button press
		if (self.owner.button2 == 1 && self.owner.attack_finished < time)
		{
			self.owner.attack_finished = time + 0.5;
			self.owner.button2 = 0;
			self.owner.nextthink = time;
			self.owner.think = Exit_HorrorScope;
			return;
		}


		hr_SetViewPort_Cam ();		//set viewport every frame so player cant look around
		self.impulse = 0;
	}
};


//================================ LINE OF SIGHT ================================

//==========================================================
// returns TRUE if vector v has line of sight to self.origin
//==========================================================
float(vector v) hr_visible =
{
	traceline (v, self.origin, TRUE, self);
	
	if (trace_fraction == 1)
		return TRUE;

	return FALSE;
};

//======================================================
// returns TRUE if targ is in front of camera (in frame)
//======================================================
float(entity targ) hr_infront =
{
	local vector	vec;
	local float	dot, val;
	
	
	makevectors (self.angles);
	vec = normalize (targ.origin + targ.view_ofs - self.origin);

	dot = vec * v_forward;
	
	if (cvar ("fov") < 90)
		val = 0.85;
	else
		val = 0.6;
		
	if ( dot > val)
	{
		return TRUE;
	}

	return FALSE;
};


//================================ CAMERA POSITION ================================

//======================================
// returns a random vector nearby aiment
//======================================
vector(entity e) calc_camera_spot =
{
	local vector 	org, spot, end, tmp;
	local float	pc, cam_dist;


	if (e == world)	return e.origin;	//exit or this will cause a loop error later

	org = e.origin;

	pc = CONTENT_SKY;

	while (pc != CONTENT_EMPTY && pc != CONTENT_WATER)	
	{
		//random angle
		tmp_x = random()*-90 + random()*20;
		tmp_y = random()*360;	
		makevectors (tmp);

		//calc cam distance from org
		cam_dist = HR_MAX_CAM_DIST - HR_MIN_CAM_DIST;
		cam_dist = HR_MIN_CAM_DIST + (cam_dist * random());
		if (cam_dist > HR_MAX_CAM_DIST)
			cam_dist = HR_MAX_CAM_DIST;

		//trace org + direction * distance
		traceline (org, org + v_forward * cam_dist, TRUE, e);

		//check poincontents at end pos
		pc = pointcontents (trace_endpos);

		//double check line of sight by tracing endpos back to e.origin
		end = trace_endpos;
		traceline (end, org, TRUE, e);
		if (trace_fraction < 1)
			pc = CONTENT_SOLID;	
	}

	//found a spot!  now adjust spot away from wall back towards org by 20%
	spot = end - ((end - org) * 0.2);

	return spot;
};

//================================ CAMERA ANGLE ================================


//===================================
// move camera y_angle towards aiment
//===================================
void(vector dir, float speed_cap) update_cam_angles_y =
{
	local float  current_yaw;	// cameras current y angle
	local float  ideal;		// where camera should be facing
	local float  move;		// the amount to shift camera on y axis
	local float  speed, s; 		// the amount to shift camera increment from last angles shift

	dir = normalize(dir);
	ideal = vectoyaw(dir);
	current_yaw = anglemod( self.angles_y );
	
	if (current_yaw == ideal)	//already facing ideal angle
		return;
	
	move = ideal - current_yaw;

	//turn the shortest distance
	if (ideal > current_yaw)
	{
		if (move > 180)
			move = move - 360;
	}
	else
	{
		if (move < -180)
			move = move + 360;
	}

	//speed
	s = move;
	if (s < 0) 
		s = s*s;

	s = s * 0.1;

	if (s > self.last_y_speed + 0.1)
		s = self.last_y_speed + 0.1;

	if (s > speed_cap) s = speed_cap;

	speed = s;
	self.last_y_speed = speed;

	if (move > 0)
	{
		if (move > speed)
			move = speed;
	}
	else
	{
		if (move < 0-speed )
			move = 0-speed;
	}

	current_yaw = anglemod (current_yaw + move);

	self.angles_y = current_yaw;
};


//===================================
// move camera x_angle towards aiment
//===================================
void(vector dir, float speed_cap) update_cam_angles_x =
{
	local float  current_pitch;	// cameras current x angle
	local float  ideal;		// where camera should be facing
	local float  move;		// the amount to shift camera on x axis
	local float  speed, s; 		// the amount to shift camera increment from last angles shift

	dir = normalize(dir);
	dir = vectoangles(dir);
	ideal = dir_x;

	current_pitch = anglemod( self.angles_x );
	
	if (current_pitch == ideal)
		return;
	
	move = ideal - current_pitch;

	//turn the shortest distance
	if (ideal > current_pitch)
	{
		if (move > 180)
			move = move - 360;
	}
	else
	{
		if (move < -180)
			move = move + 360;
	}
	
	//speed 
	s = move;
	if (s < 0) s = s*s;

	s = s * 0.1;
	
	if (s > self.last_x_speed + 0.1)
		s = self.last_x_speed + 0.1;

	if (s > speed_cap) s = speed_cap;

	speed = s;
	self.last_x_speed = speed;

	if (move > 0)
	{
		if (move > speed)
			move = speed;
	}
	else
	{
		if (move < 0-speed )
			move = 0-speed;
	}

	current_pitch = anglemod (current_pitch + move);

	self.angles_x = current_pitch;
};


//=================================
// move camera angles toward aiment
//=================================
void(entity targ, float speed_cap) camera_update_angles =
{
	local vector dir1, dir2;

	dir1 = (targ.origin + targ.view_ofs) - self.origin;
	dir2 = self.origin - (targ.origin + targ.view_ofs);

	update_cam_angles_y (dir1, speed_cap);
	update_cam_angles_x (dir2, speed_cap);
};


//================================================
// set camera angles to instantly center on aiment
//================================================
void(vector vec) camera_snap =
{
	if (!vec || vec == '0 0 0')
		vec = ((self.aiment.origin + self.aiment.view_ofs) - self.origin);

        vec = normalize (vec);
	vec = vectoangles (vec);

	//don't turn camera upside down
        if (vec_x > 0)
        	vec_x = 0 - vec_x;
        else
        	vec_x = 360 - vec_x;

	self.angles_x = vec_x;
	self.angles_y = vec_y;
};

//==========================================================
// message client to set FOV to value, enforce min/max value
//==========================================================
void(float value) set_FOV =
{
	if (value < 30)
		value = 30;

	if (value > 100)
		value = 100;

	stuffcmd (self.owner, "fov ");
	stuffcmd (self.owner, ftos (value));
	stuffcmd (self.owner, "\n");
};


//================================ CAMERAS ================================
// [NOTE] Add your own cameras to this section. see '/hrscope/demo/cameras'


//=====================
// basic/default camera
//
// self = camera
//=====================
void() camera_default =
{	
	local vector 	vec, cam_pos;

	//find a target to aim camera at
	if (!self.aiment)
	{
		self.aiment = find (world, classname, "info_player_start");
		hr_print ("NO TARGET! You must specify entity .aiment\ndefault to 'info_player_start'\nDefault to 'info_player_start'\n");
	}

	//find a position for camera
	cam_pos = calc_camera_spot (self.aiment);	
	setorigin (self, cam_pos);

	//snap camera angles to aiment
	vec = (self.aiment.origin + self.aiment.view_ofs - cam_pos);
	camera_snap(vec);

	//update player
	self.owner.velocity = self.velocity;

	self.nextthink = time + 6;
	self.think = camera_default;
};

//======================= START / STOP HORROR-SCOPE =======================


//======================================
// reset player in his original position
//
// self = player
//======================================
void() Exit_HorrorScope =
{
	//reset player
	self.flags = self.flags - (self.flags & (FL_NOTARGET | FL_GODMODE));
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.angles = self.hr_oldangles;
	self.movetype = MOVETYPE_WALK;
	self.view_ofs = '0 0 25';
	setmodel (self, "progs/player.mdl");
	self.classname = "player";
	setsize (self, '-16 -16 -24', '-16 -16 -24');
	setorigin (self, self.hr_oldorigin);
	W_SetCurrentAmmo();

	//console settings
	stuffcmd (self, "v_centerspeed 500\nv_centermove 0.15\ncl_bob 0.02\ncl_rollangle 0.2\nfov 90\n");
	
	//remove camera
	remove (self.cam);
	self.cam = world;

	hr_SetViewPort_Player();
};

//===============================
// start a new HorrorScope camera
//
// self = player
//===============================
void (void() run_cam) HorrorScope = 
{
	if (self.cam)
		remove (self.cam);

	//spawn camera
	self.cam = spawn();
	self.cam.owner = self;
	self.cam.solid = SOLID_NOT;
	self.cam.movetype = MOVETYPE_NOCLIP;
	self.cam.classname = "camera";
	self.cam.origin = self.origin;
	setmodel (self.cam, "progs/spike.mdl");

	//setup player
	self.weaponmodel = "";
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NOCLIP;
	self.view_ofs = '0 0 0';
	setsize (self, '0 0 0', '0 0 0');
	setmodel (self, "");
	self.flags = self.flags | FL_NOTARGET | FL_GODMODE;
	self.classname = "hr_player";
	setorigin (self, self.origin);

	//console settings
	stuffcmd (self, "v_centerspeed 0\nv_centermove 0\ncl_bob 0\ncl_rollangle 0\n");

	//no cam specified - run default
	if (!run_cam)
		run_cam = camera_default;

	//run camera
	self.cam.nextthink = time;
	self.cam.think = run_cam;
};	


//========================
// print message to player
//========================
void(string str) hr_print =
{
	local entity e;


	if (hr_print_info == FALSE)
		return;

	if (self.owner.classname == "hr_player")
		e = self.owner;

	else if (self.classname == "hr_player")
		e = self;

	sprint (e, "HorrorScope --> ");
	sprint (e, str);
	sprint (e, "\n");

};
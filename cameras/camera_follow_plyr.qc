//camera_follow_plyr.qc
/*===========================================================
 FOLLOW PLAYER CAMERA

 Continuously follow player around while keeping him centered
 in frame.  Players move so much faster and more dynamically
 than monsters, so they need a separate camera.  

<NOTE>
 See 'camera_follow.qc' for monster following camera
===========================================================*/

//NEW FIELD
.float lefty;
.float lefty_time;

//PROTOTYPES
void() camera_follow_plyr;
void() camera_follow_plyr_think;

//==================================================
// Find a player and set .camera_spot in view of him
//==================================================
void() camera_follow_plyr =
{
	entity 	plyr;


	//find player
	if (self.aiment.classname != "player")
	{
		plyr = find (world, classname, "player");
	
		//player not found
		if (!plyr)
		{
			hr_print ("Follow Player Camera\nNo player found... connect a multiplayer game");
			camera_static();
			return;
		}		

		self.aiment = plyr;
	}

	//stop camera movement
	self.velocity = '0 0 0'; 	
	self.avelocity = '0 0 0'; 

	hr_print ("Follow Player Camera");

	//find camera position
	self.camera_spot = calc_camera_spot (self.aiment);

	//place camera
	setorigin (self, self.camera_spot);
	setorigin (self.owner, self.origin);
	self.lefty = 1;

	//snap camera angles to face aiment
	camera_snap (self.aiment.origin + self.aiment.view_ofs - self.camera_spot);

	//wait until next frame
	self.nextthink = time;
	self.think = camera_follow_plyr_think;
};

//============================================
// Setup camera at .camera_spot and run camera
//============================================
void() camera_follow_plyr_think =
{
	vector 	dir, v;
	float 	ideal_speed, speed, aiment_speed;


	//update camera owners origin
	setorigin (self.owner, self.origin);

	//aiment dead
	if (self.aiment.health <= 0)
	{
		self.nextthink = time + 1;
		self.think = camera_follow_plyr;
		if (hr_visible (self.aiment.origin))
			self.velocity = self.velocity * 0.1;

		return;
	}

	//aiment teleported
	if (self.aiment.teleport_time > time)
	{
		self.nextthink = time + 0.5;
		self.think = camera_follow_plyr;
		self.aiment.teleport_time = time;
		return;
	}

	//store vector where aiment was last sighted
	if (hr_visible (self.aiment.origin))
		self.last_sight = self.aiment.origin;	

	//find ideal height for camera relative to .aiment velocity
	v_z = 512 - (vlen ((self.aiment.velocity * 0.5)));
	if (v_z < 64) v_z = 64;

	if (self.lefty_time < time)
	{
		self.lefty = 0 - self.lefty;
		self.lefty_time = time + 10;
	}

	//find camera spot
	makevectors (self.aiment.angles);
	traceline (self.aiment.origin, self.aiment.origin + v + v_forward * (v_z * self.lefty), TRUE, self.aiment); //above and behind
	vector pos1 = trace_endpos;		

	if ( vlen (self.aiment.origin - pos1) < 32)
		self.lefty = 0 - self.lefty;

	//adjust endpos away from walls back towards org
	self.camera_spot = (pos1 - self.aiment.origin) * 0.2;
	self.camera_spot = pos1 - self.camera_spot;


	//chosen camera spot is not visible to camera
	if (!hr_visible (self.camera_spot))
	{
		if (vlen (self.origin - self.last_sight) > 32)
			self.camera_spot = self.last_sight;	//fall back to last_sight
		else
			self.camera_spot = self.aiment.origin;	//already at last_sight, go direct to aiment
	}

	//calc cam move speed
	ideal_speed = vlen(self.camera_spot - self.origin) * 0.5;	//ideal velocity relative to half camera distance from camera_spot
	speed = vlen (self.velocity);			//camera current velocity
	aiment_speed = vlen (self.aiment.velocity);	//aiment current velocity

	if (aiment_speed > ideal_speed)
		ideal_speed = ideal_speed + aiment_speed;
	
	if (ideal_speed > speed)
		speed = speed + 3;	//increment speed
	else
	{
		if (hr_visible (self.aiment.origin))
			speed = ideal_speed;
		else
			speed = speed + vlen (self.aiment.origin - self.origin);	//aiment not visible, set velocity relative to aiment dist from self
	}

	camera_update_angles(1.5);	//update cam angles toward aiment

	dir = normalize (self.camera_spot - self.origin); //calc bearing
	self.velocity = dir * speed;	//move camera in direction at speed


	self.nextthink = time;
	self.think = camera_follow_plyr_think;
};

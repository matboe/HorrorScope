//camera_follow.qc
/*======================================================================
 FOLLOW CAMERA

 Find a camera position in view of .aiment
 Move camera toward .camera_spot until camera is:
	a) not visible to .camera_spot
 	b) shot time expires
 Find another position and repeat
======================================================================*/

//NEW FIELDS
.vector camera_spot;
.vector last_sight;

//PROTOTYPES;
void() camera_follow;
void() camera_follow_setup;
void() camera_follow_think;

//==================================================
// Find a spot for camera and point camera at aiment
//==================================================
void() camera_follow =
{
	hr_print ("Follow Camera");

	//find camera position
	self.camera_spot = calc_camera_spot (self.aiment);

	//snap camera angles to face aiment
	camera_snap(self.aiment.origin + self.aiment.view_ofs - self.camera_spot);

	//wait until next frame
	self.nextthink = time;
	self.think = camera_follow_setup;
};

//============================================
// Setup camera at .camera_spot and run camera
//============================================
void() camera_follow_setup =
{
	set_FOV (90);

	//place camera
	setorigin (self, self.camera_spot);
	setorigin (self.owner, self.origin);

	camera_follow_think();	
};


//=======================================================
// Find a position in view of .aiment and move camera
// toward it. Store .aiment.origin when it is visible to 
// the camera (.last_sight)  
// If the new position is not visible to the camera then
// move camera to .last sight instead  
//======================================================
void() camera_follow_think =
{
	local vector 	dir;
	local float 	ideal_speed, speed;


	//aiment dead
	if (self.aiment.health <= 0)
	{
		self.owner.aiment = world; //static camera will find a new aiment
		self.nextthink = time + 1;
		self.think = camera_static;
		return;
	}

	if (hr_visible (self.aiment.origin) && vlen (self.velocity) > 32 )
		self.shot_time = time + 1;

	//camera_spot not visible, shot time expired, or no vector for camera
	if ( !hr_visible(self.camera_spot) || self.shot_time < time || !self.camera_spot )
	{
		self.camera_spot = calc_camera_spot (self.aiment);
		self.shot_time = time + 5;
	}

	//cant see camera_spot, go for aiments last known positon
	if (!hr_visible (self.camera_spot))
	{
		traceline (self.last_sight, self.aiment.origin, TRUE, self);
		if (trace_fraction == 1)
			self.camera_spot = self.last_sight; 
		else
			self.camera_spot = self.aiment.origin; 
	}
	
	speed = vlen (self.velocity);

	//calc cam move speed
	ideal_speed = vlen(self.camera_spot - self.origin) * 0.5;	
	
	if (ideal_speed > speed)
		speed = speed + 2;
	else
		speed = ideal_speed;


	dir = normalize (self.camera_spot - self.origin); //calc bearing
 	self.velocity = dir * speed;	//move camera in direction at speed

	camera_update_angles(self.aiment, 0.9);	//update cam angles toward aiment

	self.last_sight = self.aiment.origin; 

	setorigin (self.owner, self.origin);	//update player


	self.nextthink = time;
	self.think = camera_follow_think;
};

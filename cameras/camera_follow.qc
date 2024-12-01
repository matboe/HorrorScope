//camera_follow.qc
/*======================================================================
 FOLLOW CAMERA

 Find a camera position in view of .aiment
 Adjust camera speed (speed x distance for smooth effect)
 Adjust camera angles each frame to keep .aiment  centered
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
void() camera_follow_think;

//==================================================
// Find a position for camera and point at aiment
//==================================================
void() camera_follow =
{
	hr_print ("Follow Camera");

	//find camera position
	self.camera_spot = calc_camera_spot (self.aiment);

	//place camera
	setorigin (self, self.camera_spot);

	//snap camera angles to face aiment
	camera_snap(self.aiment.origin + self.aiment.view_ofs - self.camera_spot);

	//start camera
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
	vector 	dir;
	float 	ideal_speed, speed;


	//aiment dead
	if (self.aiment.health <= 0)
	{
		self.owner.aiment = world; //default camera will find a new aiment
		self.nextthink = time + 2;
		self.think = camera_default; //reset to default camera
		return;
	}

	if (hr_visible (self.aiment.origin))
		if (vlen (self.velocity) > 32 )
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
	
	//increment camera movement speed
	if (ideal_speed > speed)
		speed = speed + 2;	
	else
		speed = ideal_speed;

	//calc bearing
	dir = normalize (self.camera_spot - self.origin); 
	//move camera in direction at speed
 	self.velocity = dir * speed;	
	//update cam angles toward aiment
	camera_update_angles(0.9);	
	//store aiments last known position
	self.last_sight = self.aiment.origin; 

	//update player position to match camera
	setorigin (self.owner, self.origin);	


	self.nextthink = time;
	self.think = camera_follow_think;
};

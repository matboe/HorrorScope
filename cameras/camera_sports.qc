//camera_sports.qc
/*======================================================================
 SPORTS CAMERA - Emulate a TV sports camera
 
 Find a camera position in view of .aiment
 Adjust camera angles to keep .aiment centered.
 Adjust FOV to emulate a zoom lens
 Switch to next camera position when .aiment is:
	a) not visibile to camera
 	b) shot time expires
======================================================================*/

// PROTOTYPES
void() camera_sports;
void() camera_sports_setup;
void() camera_sports_think;

//================================================
// Measure distance between camera and .aiment and 
// use the value to calculate ideal FOV setting
// Increment FOV to ideal value
//================================================
void() adjust_fov =
{
	local float 	dist, current, ideal;

	
	//measure distance camera --> aiment
	dist = vlen (self.aiment.origin - self.origin);
	dist = dist * 0.1;

	//cap dist value
	if (dist > 120) dist = 120;
//	if (dist < 1) dist = 1;

	//find current fov setting
	current = cvar ("fov");
	ideal = 120 - dist;

	//message client to set fov by increments
	if (current < ideal)
	{
		stuffcmd (self.owner, "fov ");
		stuffcmd (self.owner, ftos (current + 0.25));
		stuffcmd (self.owner, "\n");
	}

	else if (current > ideal)
	{
		stuffcmd (self.owner, "fov ");
		stuffcmd (self.owner, ftos (current - 0.25));
		stuffcmd (self.owner, "\n");
	}
};

//============================================================
// Find a spot for camera nearby aiment and point camera at it
//============================================================
void() camera_sports =
{	
	hr_print ("Sports camera");

	//camera position 
	self.camera_spot = calc_camera_spot (self.aiment);

	//snap camera angles to face .aiment
	camera_snap ((self.aiment.origin + self.aiment.view_ofs) - self.camera_spot);

	//wait until next frame
	self.nextthink = time;
	self.think = camera_sports_setup;
};


//============================================
// Setup camera at .camera_spot and run camera
//============================================
void() camera_sports_setup  =
{	
	//setup camera
	setorigin (self, self.camera_spot);
	self.shot_time = time + 7;
	self.velocity = '0 0 0';	//stop camera movement
	
	//setup player
	setorigin (self.owner, self.origin);
	self.owner.velocity = self.velocity;

	camera_sports_think();
};


//==================================================
// Check for aiment out of shot or shot_time expired
// Update camera angles to face .aiment
// Adjust FOV
// Runs every frame
//==================================================
void() camera_sports_think  =
{	
	//aiment not visible or shot time expired
	if ( !hr_visible(self.aiment.origin) || self.shot_time < time )
	{
		//go to next cam position		
		camera_sports();
		return;
	}

	//update camera angles
	camera_update_angles(self.aiment, 2);				

	//increment FOV accoring to camera distance from .aiment
	adjust_fov();
		
	self.nextthink = time;
	self.think = camera_sports_think;
};

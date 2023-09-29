//camera_static.qc
/*======================================================================
 STATIC CAMERA

 Standard non-moving camera

 Find best entity for aiment (hr_findtarget)
 Find a position in view of aiment
 Snap camera angles to aiment
 Hold position until aiment is:
	a) no longer in front of camera
	b) not visible to camera
 	c) shot time expires
 Find another position and repeat
======================================================================*/

//PROTOTYPES
void() camera_static;
void() camera_static_setup;
void() camera_static_think;

//===================================================
// Find a spot for camera and point camera at .aiment
//===================================================
void() camera_static =
{	
	hr_print ("Static camera");

	//check camera has a target
	if (!self.aiment)
		self.aiment = hr_findtarget();

	//camera position 
	self.camera_spot = calc_camera_spot (self.aiment);

	//snap camera angles to face .aiment
	camera_snap ((self.aiment.origin + self.aiment.view_ofs) - self.camera_spot);

	//wait until next frame
	self.nextthink = time;
	self.think = camera_static_setup;
};

//============================================
// Setup camera at .camera_spot and run camera
//============================================
void() camera_static_setup =
{
	set_FOV (90);

	//setup camera
	setorigin (self, self.camera_spot);
	self.shot_time = time + 7;
	self.velocity = '0 0 0'; 	//stop camera movement

	//update player
	setorigin (self.owner, self.origin);
	self.owner.velocity = '0 0 0';

	camera_static_think();
};

//==================================================
// Check for aiment out of shot or shot_time expired
// Runs every frame
//==================================================
void() camera_static_think  =
{	
	//check switch to next camera
	if ( !hr_infront(self.aiment) || !hr_visible(self.aiment.origin) || self.shot_time < time )
	{
		//go to next camera position
		camera_static();
		return;
	}
	
	//run this function again in the next frame
	self.nextthink = time;	
	self.think = camera_static_think;
};


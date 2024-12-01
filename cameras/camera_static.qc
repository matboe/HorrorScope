//camera_sports.qc
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
void() camera_static_think;

//===================================================
// Find a spot for camera and point camera at .aiment
//===================================================
void() camera_static =
{	
	hr_print ("Static camera");

	//setup camera
	self.shot_time = time + 7;

	//stop camera movement
	self.velocity = '0 0 0'; 	
	self.avelocity = '0 0 0'; 

	set_FOV (90);

	//camera position 
	self.camera_spot = calc_camera_spot (self.aiment);
	setorigin (self, self.camera_spot);

	//update player
	setorigin (self.owner, self.origin);
	self.owner.velocity = '0 0 0';

	//snap camera angles to face .aiment
	camera_snap ((self.aiment.origin + self.aiment.view_ofs) - self.camera_spot);

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


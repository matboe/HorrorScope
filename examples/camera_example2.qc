/*======================================================================
 EXAMPLE CAMERA 2 - Static/fixed camera

 Find a position in view of aiment
 Snap camera angles to aiment
 Hold position until aiment is:
	a) no longer in front of camera
	b) not visible to camera
 	c) shot time expires
 Find another position and repeat
======================================================================*/

//PROTOTYPES
void() camera_example2;
void() camera_example2_think;

//===================================================
// Find a spot for camera and point camera at .aiment
//===================================================
void() camera_example2 =
{	
	vector 	vec;

	hr_print ("Example camera 2\n");

	//find a position for camera
	self.camera_spot = calc_camera_spot (self.aiment);	
	setorigin (self, self.camera_spot);

	//snap camera angles to face .aiment
	vec = (self.aiment.origin + self.aiment.view_ofs - self.camera_spot);
	camera_snap(vec);

	//setup camera
	self.shot_time = time + 4;	//max shot time
	self.velocity = '0 0 0'; 

	//update player position and velocity to match camera
	setorigin (self.owner, self.camera_spot);
	self.owner.velocity = '0 0 0';

	camera_example2_think();
};

//==================================================
// Check for aiment out of shot or shot_time expired
// Runs every frame during shot
//==================================================
void() camera_example2_think  =
{	
	// go to next camera position when aiment is out of frame or shot_time expires
	if ( !hr_infront(self, self.aiment) || !hr_visible(self.aiment.origin) || self.shot_time < time )
	{
		//go to next cam position		
		camera_example2();
		return;
	}
	
	self.nextthink = time;	
	self.think = camera_example2_think;
};



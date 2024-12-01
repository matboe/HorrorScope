//camera_flytospot.qc
/*======================================================================
 FLYTOSPOT CAMERA

 Find a camera position in view of .aiment
 Move camera toward .camera_spot until camera is:
	a) not visible to camera
 	b) shot time expires
 Find a new position and repeat
======================================================================*/

//PROTOTYPES
void() camera_flytospot;
void() camera_flytospot_think;

//===================================================
// Find a spot for camera and point camera at .aiment
//===================================================
void() camera_flytospot =
{
	float	dist;
	vector 	dir, spot1, spot2;


	hr_print ("Fly to spot camera");

	set_FOV (90);

	//camera position 
	self.camera_spot = calc_camera_spot (self.aiment);

	//find 2 spots for camera
	spot1 = self.camera_spot;
	spot2 = calc_camera_spot (self.aiment);

	//setup camera
	setorigin (self, spot1);
	self.shot_time = time + 8;	//maximum shot time
	//stop camera movement
	self.velocity = '0 0 0'; 	
	self.avelocity = '0 0 0'; 

	//calc bearing / velocity
	dist = vlen (spot2 - spot1);
	dir = normalize (spot2 - spot1);
	self.velocity = dir * (dist * 0.2);

	//snap camera angles to face .aiment
	camera_snap ((self.aiment.origin + self.aiment.view_ofs) - self.camera_spot);

	camera_flytospot_think();
};

//==================================================
// Check for aiment out of shot or shot_time expired
// Stop camera movement when blocked
// Runs every frame
//==================================================
void() camera_flytospot_think =
{
	vector 	cam_dir;

	//check switch to next camera
	if ( !hr_visible(self.aiment.origin) || self.shot_time < time )
	{
		//go to next camera position
		camera_flytospot();
		return;
	}
					
	//decrease velocity to zero when movement is blocked within 32 units in direction of travel 
	cam_dir = normalize (self.velocity);
	traceline (self.origin, self.origin + cam_dir * 48, TRUE, self);
	if (trace_fraction < 1)
		self.velocity = self.velocity * 0.95;

	//update players origin to match camera
	setorigin (self.owner, self.origin);

	//run this function again in the next frame
	self.nextthink = time;
	self.think = camera_flytospot_think;		
};


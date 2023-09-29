//camera_flytospot.qc
/*======================================================================
 FLYTOSPOT CAMERA

 Find a camera position in view of .aiment
 Adjust camera angles to keep aiment centered.
 Move camera toward .camera_spot until camera is:
	a) not visibile to camera
 	b) shot time expires
 Find a new position and repeat
======================================================================*/

//PROTOTYPES
void() camera_flytospot;
void() camera_flytospot_setup;
void() camera_flytospot_think;

//===================================================
// Find a spot for camera and point camera at .aiment
//===================================================
void() camera_flytospot =
{
	hr_print ("Fly to spot camera");

	//camera position 
	self.camera_spot = calc_camera_spot (self.aiment);

	//snap camera angles to face .aiment
	camera_snap ((self.aiment.origin + self.aiment.view_ofs) - self.camera_spot);

	//wait until next frame
	self.nextthink = time;
	self.think = camera_flytospot_setup;
};

//============================================
// Setup camera at .camera_spot and run camera
//============================================
void() camera_flytospot_setup =
{
	local float	dist;
	local vector 	dir, spot1, spot2;


	set_FOV (90);

	//find 2 spots for camera
	spot1 = self.camera_spot;
	spot2 = calc_camera_spot (self.aiment);

	//setup camera
	setorigin (self, spot1);
	self.shot_time = time + 8;	//maximum shot time

	//calc bearing / velocity
	dist = vlen (spot2 - spot1);
	dir = normalize (spot2 - spot1);
	self.velocity = dir * (dist * 0.2);

	//update player
	setorigin (self.owner, spot1);	

	camera_flytospot_think();
};


//==================================================
// Check for aiment out of shot or shot_time expired
// Update camera angles to face .aiment
// Stop camera movement when blocked
// Runs every frame
//==================================================
void() camera_flytospot_think =
{
	local vector 	cam_dir;

	//check switch to next camera
	if ( !hr_visible(self.aiment.origin) || self.shot_time < time )
	{
		//go to next camera position
		camera_flytospot();
		return;
	}

	//update camera angles
	camera_update_angles(self.aiment, 2);
					
	//decrease velocity to zero when movement is blocked within 32 units in direction of travel 
	cam_dir = normalize (self.velocity);
	traceline (self.origin, self.origin + cam_dir * 48, TRUE, self);
	if (trace_fraction < 1)
		self.velocity = self.velocity * 0.95;

	//update player
	setorigin (self.owner, self.origin);

	//run this function again in the next frame
	self.nextthink = time;
	self.think = camera_flytospot_think;		
};


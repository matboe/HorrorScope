/*======================================================================
 EXAMPLE CAMERA 3 - Moving camera

 Find 2 camera positions
 Move camera from 'spot1' to 'spot2' until camera is:
	a) not visible to camera
 	b) shot time expires
 Adjust camera angles to keep .aiment centered
======================================================================*/

//PROTOTYPES
void() camera_example3;
void() camera_example3_setup;
void() camera_example3_think;


//===================================================
// Find a spot for camera and point camera at .aiment
//===================================================
void() camera_example3 =
{
	local vector vec;


	hr_print ("Example camera 3\n");

	//find first camera spot
	self.camera_spot = calc_camera_spot (self.aiment);

	//turn camera to immediately face aiment
	vec = (self.aiment.origin + self.aiment.view_ofs) - self.camera_spot;
	camera_snap(vec);

	self.nextthink = time;
	self.think = camera_example3_setup;
};

//=================================================
// find a second camera position and move toward it
//=================================================
void() camera_example3_setup =
{
	local vector	spot2;


	self.shot_time = time + 8;	//maximum shot time
	setorigin (self, self.camera_spot);

	//find second camera spot
	spot2 = calc_camera_spot (self);

	//camera bearing / velocity
	self.velocity = normalize (self.camera_spot, spot2)
	self.velocity = self.velocity * 128;

	//update player
	setorigin (self.owner, self.origin);	

	camera_example3_think();
};

//==================================================
// Check for aiment out of shot or shot_time expired
// Update camera angles to face .aiment
// Stop camera movement when blocked
// Runs every frame
//==================================================
void() camera_example3_think =
{
	local vector 	cam_dir;


	//update camera angles
	camera_update_angles(self.aiment, 2);

	//check switch to next camera
	if ( !hr_visible(self.aiment.origin) || self.shot_time < time )
	{
		//go to next cam position		
		camera_example3();
		return;
	}

	//decrease velocity if movement is blocked in direction of travel 
	cam_dir = normalize (self.velocity);
	traceline (self.origin, self.origin + cam_dir * 16, TRUE, self);
	if (trace_fraction < 1)
		self.velocity = self.velocity * 0.95;

	//update player
	setorigin (self.owner, self.origin);

	self.nextthink = time;
	self.think = camera_example3_think;		
};

//camera_overhead.qc
/*===================================================================
 POV CAMERA

 Lock camera to aiments point of view
===================================================================*/

//PROTOTYPES
void() camera_pov;
void() camera_pov_think;


//=============================================
// Find a spot for camera at .aiments eye level
//=============================================
void() camera_pov =
{	
	hr_print ("POV camera");

	//setup camera
	makevectors (self.aiment.angles);
	setorigin (self, self.aiment.origin + self.aiment.view_ofs + v_forward * 2);  //place camera at aiments eye level
	self.angles_y = self.aiment.angles_y;	//camera faces aiments angles

	//update player
	setorigin (self.owner, self.origin);
	self.owner.velocity = self.velocity;	

	camera_pov_think();
};

//==================================================
// Update camera velocity and angle to match .aiment
// Runs every frame
//==================================================
void() camera_pov_think  =
{	
	local float	move_speed;
	local vector 	org;


	if (self.aiment.health <= 0)
	{
		camera_static();
		return;
	}

	if (!hr_visible (self.aiment.origin))
		setorigin (self, self.aiment.origin);

	makevectors (self.aiment.angles);
	org = self.aiment.origin + self.aiment.view_ofs + v_forward * 2;

	
	//adjust camera y angle to look directly in front of aiment
	if (self.aiment.flags & FL_MONSTER)
	{
		self.angles_x = self.aiment.angles_x;
		update_cam_angles_y (self.aiment.origin + v_forward * 128 - self.origin, 3);	
	}
	else
	{
		self.angles_x = self.aiment.v_angle_x;
		self.angles_y = self.aiment.v_angle_y;
	}

	//set velocity
	move_speed = vlen (org - self.origin);
	if (move_speed <= 0) 
		move_speed = 1;
	self.velocity = org - self.origin;
	self.velocity = self.aiment.velocity + self.velocity * (move_speed * 5);
	
	//update player
	setorigin (self.owner, self.origin);

	self.nextthink = time;
	self.think = camera_pov_think;
};

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

	//stop camera movement
	self.velocity = '0 0 0'; 	
	self.avelocity = '0 0 0'; 

	//setup camera
	makevectors (self.aiment.angles);
	setorigin (self, self.aiment.origin + self.aiment.view_ofs + v_forward * 2);  //place camera at aiments eye level
	self.angles_y = self.aiment.angles_y;	//camera faces aiments angles

	camera_pov_think();
};

//==================================================
// Update camera velocity and angle to match .aiment
// Runs every frame
//==================================================
void() camera_pov_think  =
{	
	float	move_speed;
	vector 	org;


	if (self.aiment.health <= 0)
	{
		camera_static();
		return;
	}

	if (!hr_visible (self.aiment.origin))
		setorigin (self, self.aiment.origin);
	
	//set velocity
	makevectors (self.aiment.angles);
	org = self.aiment.origin + self.aiment.view_ofs + v_forward * -0.5;

	move_speed = vlen (org - self.origin);
	if (move_speed <= 0) 
		move_speed = 1;
	self.velocity = org - self.origin;
	self.velocity = self.aiment.velocity + self.velocity * (move_speed * 5);
	
	//update player
	setorigin (self.owner, self.origin);

	//adjust camera y angle to look directly in front of aiment
	if (self.aiment.flags & FL_MONSTER)
		camera_update_angles(3);

	else
	{
		self.angles_x = self.aiment.v_angle_x;
		self.angles_y = self.aiment.v_angle_y;
	}


	self.nextthink = time;
	self.think = camera_pov_think;
};

/*======================================================================
 EXAMPLE CAMERA 1 - Most basic workable camera
 
 Place camera in a random position in view of aiment
 Snap camera angles to face aiment
 Hold position until shot time expires

 'self' refers to a new camera entity created when HorrorScope()
 function runs.
======================================================================*/

void() camera_example1 =
{	
	// enable/disable hr_print by editing hr_print_info (in hrscope-plugin.qc)
	hr_print ("Example camera 1\n");	

	//find a target
	self.aiment = find (world, classname, "info_player_start");

	//find a random position within view of .aiment
	self.camera_spot = calc_camera_spot (self.aiment);	

	//snap camera angles to face .aiment
	camera_snap (self.aiment.origin + self.aiment.view_ofs - self.camera_spot);

	//go to next camera position after time has elapsed
	self.shot_time = time + 4;
	setorigin (self, self.camera_spot);

	//update players origin and velocity
	setorigin (self.owner, self.origin);
	self.owner.velocity = self.velocity;

	// move to next camera position
	// when shot_time expires
	self.nextthink = self.shot_time;
	self.think = camera_example1;
};


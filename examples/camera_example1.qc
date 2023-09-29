/*======================================================================
 EXAMPLE CAMERA 1 - Most basic workable camera
 
 Place camera in a random position in view of aiment
 Snap camera angles to face aiment
 Hold position until shot time expires
======================================================================*/

void() camera_example1 =
{	
	hr_print ("Example camera 1\n");

	//find a target
	self.aiment = find (world, classname, "info_player_start");

	//find a random position within view of .aiment
	self.camera_spot = calc_camera_spot (self.aiment);	

	//snap camera angles to face .aiment
	camera_snap (self.aiment.origin + self.aiment.view_ofs - self.camera_spot);

	//wait until next frame
	self.nextthink = time;
	self.think = camera_example1_setup;
};

void() camera_example1_setup =
{
	self.shot_time = time + 4;	//got to next camera position after time has elapsed
	setorigin (self, self.camera_spot);

	//update player
	setorigin (self.owner, self.origin);
	self.owner.velocity = self.velocity;

	self.nextthink = self.shot_time;
	self.think = camera_example1;
};

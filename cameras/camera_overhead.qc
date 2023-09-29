//camera_overhead.qc
/*======================================================================
 OVERHEAD CAMERA

 Follow aiment while looking down from above.
======================================================================*/

// PROTOTYPES
void() camera_overhead;
void() camera_overhead_setup;
void() camera_overhead_think;

//==========================================================
// Find a spot for camera above aiment and point camera down
//==========================================================
void() camera_overhead =
{	
	hr_print ("Overhead camera");

 
	//find position above aiment
	traceline (self.aiment.origin, self.aiment.origin + '0 0 999999', TRUE, self.aiment);
	
	//adjust away from walls
	trace_endpos_z = trace_endpos_z - 8;	
	self.camera_spot = trace_endpos;	

	//snap camera angles to aiment
	camera_snap (self.aiment.origin - self.camera_spot);
	self.velocity = self.aiment.velocity;

	self.nextthink = time;
	self.think = camera_overhead_setup;
};

//============================================
// Setup camera at .camera_spot and run camera
//============================================
void() camera_overhead_setup =
{
	set_FOV (90);

	//setup camera
	setorigin (self, self.camera_spot);
	self.shot_time = time + 2;

	//setup player
	setorigin (self.owner, self.origin);
	self.owner.velocity = self.velocity;

	camera_overhead_think();
};

//=========================================================
// Check for aiment not visible, camera too close to aiment
// or shot_time expired.
// Maintain camera velocity to keep aiment directly below.
// Runs every frame
//=========================================================
void() camera_overhead_think  =
{	
	local float	move_speed;


	//go to next camera if overhead cam is not possible (ceiling too low)
	if ( !hr_visible(self.aiment.origin) || (self.origin_z - self.aiment.origin_z) < 64 && self.shot_time < time )
	{
		//go to next cam position	
		camera_overhead();
		return;
	}

	//find position above aiment
	traceline (self.aiment.origin, self.aiment.origin + '0 0 999999', TRUE, self.aiment);
	trace_endpos_z = trace_endpos_z - 8;

	//set velocity
	move_speed = vlen (trace_endpos - self.origin);
	self.velocity = normalize(trace_endpos - self.origin);
	self.velocity = self.velocity * (move_speed*2.5);
	//self.velocity_z = self.velocity_z * 0.5;

	//update player
	setorigin (self.owner, self.origin);

	self.nextthink = time;
	self.think = camera_overhead_think;
};

//camera_overhead.qc
/*======================================================================
 OVERHEAD CAMERA

 Follow aiment while looking down from above.
======================================================================*/

// PROTOTYPES
void() camera_overhead;
void() camera_overhead_think;

//==========================================================
// Find a spot for camera above aiment and point camera down
//==========================================================
void() camera_overhead =
{	
	hr_print ("Overhead camera");

	set_FOV (90);
 
	//find position above aiment
	traceline (self.aiment.origin, self.aiment.origin + '0 0 999999', TRUE, self.aiment);
	
	//adjust away from walls
	trace_endpos_z = trace_endpos_z - 8;	
	self.camera_spot = trace_endpos;	

	//setup camera
	setorigin (self, self.camera_spot);

	//snap camera angles to aiment
	self.velocity = self.aiment.velocity;
	self.avelocity = '0 0 0'; 
	camera_snap (self.aiment.origin - self.camera_spot);

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
	float	move_speed;


	//go to next camera if overhead cam is not possible (ceiling too low)
	if ( !hr_visible(self.aiment.origin) || (self.origin_z - self.aiment.origin_z) < 64)
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

	//update player position to match camera
	setorigin (self.owner, self.origin);

	self.nextthink = time;
	self.think = camera_overhead_think;
};

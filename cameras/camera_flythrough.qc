//camera_flythrough.qc
/*======================================================================
 AUTO FLYTHROUGH CAMERA

 Find every item or monster entity in the map and compare the distance
 between them to find the longest (can take a while!).
 Set camera to fly a stright line between the 2 longest points.
 When camera reaches the end of the flythrough, swap the points and
 flythrough again in the reverse direction.
 Then move to the next longest points and repeat
======================================================================*/

//NEW FIELDS
.float longest;
.entity flythrough_ctrl;
.entity save_ent1;
.entity save_ent2;
.entity longest_ent1;
.entity longest_ent2;
.vector flythrough_start;
.vector flythrough_end;

//PROTOYPES
void() camera_flythrough;

//===============================================
// check that ent is a good entity for flythrough
//===============================================
float(entity ent1, entity ent2) check_valid_ent =
{
	float pc;

	
	pc = pointcontents (ent1.origin + ent1.view_ofs + '0 0 32');
	if (pc != CONTENT_EMPTY && pc != CONTENT_WATER)
		return FALSE;

	if (ent1.classname == "hr_player" || ent1.classname == "hr_camera")
		return FALSE;

	if (ent1 == ent2)
		return FALSE;

	if (ent1.flags & FL_MONSTER)
		if (!ent1.targetname)
			return TRUE;

	if (ent1.flags & FL_ITEM)
		return TRUE;

	if (ent1.classname == "info_teleport_destination")
		return TRUE;

	return FALSE;
};

//===================================================
// compare vector length between all valid entities
// in the map and store the 2 that are furthest apart
//===================================================
float() find_longest =
{
	float 	loop;		// number of times through the 2nd while loop
	float 	d;		// distance between ent1 and ent2
	float	trace;		// count successful traces
	entity 	ent1, ent2;	// entites whose distance is being compared
	vector 	spot1, spot2;


	if (self.owner.longest <= 0)
		self.owner.longest = 99999999999;

	if (!self.save_ent1)
		self.save_ent1 = nextent (world);

	if (!self.save_ent2)
		self.save_ent2 = nextent (world);
	
	ent1 = self.save_ent1;
	ent2 = self.save_ent2;

	while (ent1)
	{
		if (check_valid_ent(ent1, ent2))
		{
			while (ent2)
			{
				if (check_valid_ent(ent2, ent1))
				{
					//find start and end points of flythrough in
					//relation to .origin ent1 and ent2
					local vector v, start, end;
					start = ent1.origin + ent1.view_ofs + '0 0 32';
					end = ent2.origin + ent2.view_ofs + '0 0 32';

					//trace start point, past ent2 to wall
					v = normalize (start - end);
					traceline (start, v * 999999, TRUE, self);
					spot1 = trace_endpos - ((trace_endpos - start)*0.2);	//set spot1 20% back from wall toward start point

					//trace end point, past ent1 to wall
					v = normalize (end - start);
					traceline (end, v * 999999, TRUE, self);
					spot2 = trace_endpos - ((trace_endpos - end)*0.2);  	//set spot2 20% back from wall toward end point

					traceline (spot1, spot2, TRUE, self);			///////////////////////////////////////////////
					if (trace_fraction == 1)				// Trace both directions (vec1 --> vec2) and //
						trace = trace + 1;				// (vec2 --> vec1) to be sure theres no geo  //
												// in the way of the flythru.                //
					traceline (spot2, spot1, TRUE, self);			///////////////////////////////////////////////
					if (trace_fraction == 1)
						trace = trace + 1;

					if (trace == 2)
					{
						d = vlen (spot2 - spot1);
						if (d > self.longest && d < self.owner.longest)
						{
							// found longest distance so far,
							// store dist and entities
							self.longest = d;
							self.longest_ent1 = ent1;
							self.longest_ent2 = ent2;
							self.owner.flythrough_start = spot1;
							self.owner.flythrough_end = spot2;

						}
					}
				}

				trace = 0;		
				loop = loop + 1;
				if (loop > 1024)
				{
					self.save_ent1 = ent1;
					self.save_ent2 = ent2;
					return FALSE;
				}
			
				ent2 = nextent (ent2);
			}
		}
		ent1 = nextent (ent1);
		ent2 = nextent (world);
	}

	return TRUE;
};


//===================================
// find 2 spots and start HorrorScope
//===================================
void() ctrl_think =
{
	if (find_longest() == TRUE)
	{
		local float dist;
		dist = vlen (self.longest_ent2.origin - self.longest_ent1.origin);

		//no flythrough path found
		if (dist == 0)
		{
			hr_print ("no path found");
			remove (self);

			return;
		}

		//store current longest entities
		self.owner.longest_ent1 = self.longest_ent1;
		self.owner.longest_ent2 = self.longest_ent2;

		//store .longest dist with player, the next run will be the next longest
		self.owner.longest = self.longest;

		//start flythrough
		local entity tself;
		tself = self;		
		self = self.owner;
		HorrorScope (camera_flythrough);
		self = tself;

		//remove ctrl
		remove (self);
		return;
	}

	hr_print ("finding longest...\n");

	self.nextthink = time;
	self.think = ctrl_think;
};

//=================================================================
// Scrubbing though the edict list repeatedly will cause an 
// infinite loop error in some source ports. Handle this by 
// spawning a new entity that will search the list one
// entity at a time for a set number of loops, and then 
// store the currently held entity (.save_ent).
// In the next frame recover the position in the list by 
// starting the search beginning with the stored entity (.save_ent)
//=================================================================
void() find_flythrough =
{
	//already searching for flythoughs 
	if (self.flythrough_ctrl)
		return;

	//spawn a new flythrough ctrl
	self.flythrough_ctrl = spawn();
	self.flythrough_ctrl.owner = self.owner;
	self.flythrough_ctrl.nextthink = time;
	self.flythrough_ctrl.think = ctrl_think;
};


//====================================================
// Restart the flythrough when a solid obstacle is met
// Runs every frame
//====================================================
void() camera_flythrough_think =
{
	local vector spot1, spot2;

	makevectors (self.angles);
	traceline (self.origin, self.origin + v_forward * 32, TRUE, self);

	if (trace_fraction < 1)
	{
		//reverse spot1 and spot2 to flythrough the other way
		spot1 = self.owner.flythrough_start;
		spot2 = self.owner.flythrough_end;
		self.owner.flythrough_start = spot2;
		self.owner.flythrough_end = spot1;

		camera_flythrough();
		return;
	}

	self.nextthink = time;
	self.think = camera_flythrough_think;	
};


//=================================================================
// Move camera between stored entites longest_ent1 and longest_ent2
//=================================================================
void() camera_flythrough =
{
	float	dist;
	vector 	dir, spot1, spot2, vec;


	set_FOV (90);

	hr_print ("Auto Flythrough camera");

	//print dev info
	hr_print (self.owner.longest_ent1.classname); hr_print (" <-- spot1\n");
	hr_print (self.owner.longest_ent2.classname); hr_print (" <-- spot2\n");

	spot1 = self.owner.flythrough_start;
	spot2 = self.owner.flythrough_end;

	vec = spot2 - spot1;
	setorigin (self, spot1);

	//calc bearing / velocity
	dist = vlen(vec);
	if (dist > 4000)
		dist = 4000;
	dir = normalize (vec);

	self.velocity = dir * (dist*0.1);

	//update player
	setorigin (self.owner, self.origin);	

	//snap camera angles to aiment
	camera_snap (vec);

	camera_flythrough_think();
};

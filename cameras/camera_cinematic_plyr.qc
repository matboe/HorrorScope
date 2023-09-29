//camera_cinematic_plr.qc
/*==========================================================
 Cinematic Player Camera

 An attempt to auto generate meaningful cinematic scenes.
 Camera will choose a random position and shift angles to
 keep aiment centered.
 Camera will reset to a new position when:
	a) aiment is not visible
 	b) shot time expires

 If the player is fighting the camera will find a second 
 position and move toward it for a flyover effect.
 
 When possible the camera will switch targets to focus 
 on the players .enemy instead of the player.

 When player is standing on a platform / train / door
 the camera will find a position above the player, and
 follow the plats velocity as it moves.

<NOTE>
 To allow for tracking players enemy and plats
 add extra lines to T_Damage in 'combat.qc', near the top.
------------------------------------------------------------

	if (!targ.takedamage)
		return;

//------------ new code -----------
	// HorrorScope - store players last enemy entity
	if (attacker.flags & FL_CLIENT)
		if (targ.flags & FL_CLIENT || targ.flags & FL_MONSTER)
			if (damage < targ.health)
				attacker.last_enemy = targ;
//---------- end new code ---------
 
	//used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;

==========================================================*/

//PROTOTYPES
void() camera_cinematic_plyr;
void()camera_cinematic_plyr_setup;
void() camera_cinematic_plyr_think;

float intermission_running;
.entity last_aiment;

//====================================================================
// Find player entity and store as .aiment
// Find a position nearby aiment
// When aiment is fighting choose a second position and move camera
// When aiment is standing on a plat/door/train move camera to follow
// Select players enemy as aiment
//====================================================================
void() camera_cinematic_plyr =
{
	local float	dist;
	local vector 	dir, spot1, spot2, vec;
	local entity	plat, plyr;


	//find player
	if (self.aiment.classname != "player")
	{
		plyr = find (world, classname, "player");
	
		//player not found
		if (!plyr)
		{
			hr_print ("Cinematic Player Camera\nNo player found... connect a multiplayer game");
			camera_static();
			return;
		}		

		self.aiment = plyr;
	}

	hr_print ("Follow Player Camera");

	//place camera above plat
	if (self.aiment.classname == "player")
	{
		//check below players feet for plat	
		traceline (self.aiment.origin, self.aiment.origin + ' 0 0 -128', TRUE, self.aiment);

		if (trace_ent.state > 0 && trace_ent.state != STATE_BOTTOM && trace_ent.state != STATE_TOP)  //standing on plat
		{
			plat = trace_ent;
			traceline (self.aiment.origin, self.aiment.origin + '0 0 256', TRUE, self.aiment);
			self.aiment.last_enemy = plat;
			spot1 = trace_endpos - ((trace_endpos - self.aiment.origin) * 0.2);	//step back 20% from wall toward aiment 
		}
	}

	//enemy becomes aiment
	if (self.last_aiment.classname == "player")
	{
		if (self.aiment.last_enemy.health > 0)
		{
			if (self.aiment.last_enemy.enemy == self.aiment)
			{
				traceline (self.aiment.origin, self.aiment.last_enemy.origin, FALSE, self.aiment);
				if (trace_fraction == 1)	
					self.aiment = self.aiment.last_enemy;
			}
		}
	}

	//camera position
	if (!plat)
		spot1 = calc_camera_spot (self.aiment);	

	vec = (self.aiment.origin + self.aiment.view_ofs) - spot1;
	camera_snap(vec);

	self.velocity = '0 0 0';

	//move camera when fighting
	if (self.aiment.attack_finished + 1 > time && !plat)
	{
		spot2 = calc_camera_spot (self.aiment);

		//calc bearing / velocity
		dist = vlen(spot2 - spot1);
		dir = normalize (spot2 - spot1);
		self.velocity = dir * (dist*0.2);
	}

	self.camera_spot = spot1;

	if (plat)
		self.velocity = plat.velocity;			

	//zoom
	local float dist1, dist2, chance;
	dist1 = vlen (spot1 - self.aiment.origin);
	dist2 = vlen (spot2 - self.aiment.origin);

	if (dist1 >= HR_MAX_CAM_DIST && dist2 >= HR_MAX_CAM_DIST) chance = 1;
	else if (dist1 > (HR_MAX_CAM_DIST*0.5)) chance = 0.5;
	else chance = 0;

	if (chance && random() < chance)
		set_FOV (90 - (dist1*0.2));
	else
		set_FOV (90);

	//dev info
	//bprint (ftos (dist1)); bprint (" <-- dist\n");
	//bprint (ftos (cvar ("fov"))); bprint (" <-- fov\n");

	self.last_aiment = self.aiment;	//camera last_enemy used to store last aiment
	self.shot_time = time + 5;	//maximum shot time

	self.nextthink = time;
	self.think = camera_cinematic_plyr_setup;
};

//============================================
// Setup camera at .camera_spot and run camera
//============================================
void() camera_cinematic_plyr_setup =
{
	setorigin (self, self.camera_spot);
	setorigin (self.owner, self.origin);

	camera_cinematic_plyr_think();
};

//================================================
// Update camera angles to keep .aiment centered
// Switch to next camera position when .aiment
// is not visible to camera or .shot time expired.
// Runs every frame
//================================================
void() camera_cinematic_plyr_think =
{
	local vector 	cam_dir;
	local float	aiment_visible;
	local entity 	plat;
	
	//dont show player during intermission
	if (intermission_running)
	{
		setmodel (self.aiment, "progs/spike.mdl");
		makevectors (self.aiment.angles);
		setorigin (self, self.aiment.origin + v_up * 12);
		setorigin (self.owner, self.origin);
		self.angles = self.aiment.angles;
		return;
	}

	//limit shot time for dead monster
	if (self.aiment.classname != "player")
		if (self.aiment.health <= 0)
			if (self.shot_time > time + 2)
				self.shot_time = time + 2;

	
	aiment_visible = hr_visible(self.aiment.origin);

	//extend shot time for long flythrough
	if (self.aiment.classname == "player")
		if (self.aiment.last_enemy.movetype != SOLID_BSP) //not standing on a plat
			if (vlen (self.velocity) > 96)
				aiment_visible = TRUE;

	//check switch to next camera
	if ( (!aiment_visible && self.shot_time < (time + 4) ) || self.shot_time < time)
	{
		camera_cinematic_plyr();
		return;
	}

	//update camera angles
	camera_update_angles(self.aiment, 10);


	//aiment on plat, follow plat velocity
	if (self.aiment.last_enemy.solid == SOLID_BSP)
	{
		plat = self.aiment.last_enemy;
		traceline (self.aiment.origin, self.aiment.origin + '0 0 -128', TRUE, self.aiment); //check standing on plat

		if (trace_ent == plat && trace_ent.state > 0 && trace_ent.state != STATE_BOTTOM && trace_ent.state != STATE_TOP)  //plat is moving
			self.velocity = plat.velocity;  //follow plat velocity
		else
			self.velocity = 0;	//stop moving camera when plat stops moving
	}

	//decrease velocity when movement is blocked within 16 units in direction of travel 
	cam_dir = normalize (self.velocity);
	traceline (self.origin, self.origin + cam_dir * 16, TRUE, self);
	if (trace_fraction < 1)
	{
		if (plat)
			self.velocity = 0;
		else
			self.velocity = self.velocity * 0.95;
	}

	//update player
	setorigin (self.owner, self.origin);

	self.nextthink = time;
	self.think = camera_cinematic_plyr_think;		
};

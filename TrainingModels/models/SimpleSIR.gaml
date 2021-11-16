/**
* Name: SimpleSIR
* Based on ideas from https://www.washingtonpost.com/graphics/2020/world/corona-simulator/ 
* Author: kevinchapuis
* Tags: 
*/


model SimpleSIR

global {
	
	// Global
<<<<<<< Updated upstream
	int nb <- 100;
	
	// Epidemic
	float contact_distance <- 2#m;
	int recover_after <- 50;
=======
	int nb_people <- 1000;
	
	// Epidemic
	float contact_dist <- 2#m;
	int recover_after <- 50#cycle;
>>>>>>> Stashed changes
	float i_prop_start <- 0.05;
	
	// Policy
	float social_distancing <- -1.0 parameter:true among:[-1.0,0.0,5.0,10.0,20.0] category:"policy";
	float allowed_workers <- 0.2 parameter:true min:0.0 max:1.0 category:"policy";
	
	int time_after_realeasing_policies <- 100 parameter:true min:0 category:"policy";
	
	bool quarantine <- true parameter:true category:"policy";
	bool lockdown <- true parameter:true category:"policy";
	int nb_lockdown_space <- 4 parameter:true among:[4,9,16,25,36,49,64,81,100] category:"policy";
	list<geometry> lspace;
	
	// Display
	map<string,rgb> state_colors <- ["S"::#green,"I"::#red,"R"::#blue];
	
	// Observer
	int state_s -> people count (each.state="S");
	int state_i -> people count (each.state="I");
	int state_r -> people count (each.state="R");
	
	init {
<<<<<<< Updated upstream
		create people number:nb;
		ask int(i_prop_start*nb) among people {do infected;}
=======
		road_network <- as_edge_graph(roads_shapefile);
		create people number:nb_people{
			home <- one_of(buildings_shapefile);
			location <- any_location_in(one_of(buildings_shapefile));
		}
		ask int(i_prop_start*nb_people) among people {do infected;}
>>>>>>> Stashed changes
		do define_social_space;
		if lockdown{ do define_lockdown_space; }
	}
	
	/*
	 * Define a personal zone of social contact for agent
	 * -1 = no social distancing
	 * 0 = perfect social distancing (no contact)
	 * 10 = a small area people can interact around them
	 */
	action define_social_space {
		list<people> free_riders <- (allowed_workers*nb_people) among people;
		ask free_riders {social_space <- world.shape;}
		ask people - free_riders {
			if social_distancing=0 {social_space <- nil;} 
			else {social_space <- social_distancing < 0 ? world.shape : self buffer social_distancing;}
		}
	}
	
	/*
	 * Build zones where agent are lock inside 
	 */
	action define_lockdown_space {
		lspace <-   to_rectangles(world.shape,sqrt(nb_lockdown_space),sqrt(nb_lockdown_space),true);
		loop space over: lspace{
			if buildings_shapefile.contents none_matches (each overlaps space){
				lspace <- lspace-space;
			}
		}
		ask people { allowed_area <- first(lspace where (each overlaps home)); }
	}
	
	/*
	 * Releasing policy after "n" time step
	 */
	reflex realease_policy when:time_after_realeasing_policies > 0 and cycle = time_after_realeasing_policies {
		write "realease policy";
		ask people { social_space <- world.shape; allowed_area <- world.shape; quarantine <- false; lockdown <- false;}
	}
	
}

species people skills:[moving] {
	
	// Epi
	string state <- "S" among:["S","I","R"];
	int cycle_recover;
	
	// Move
	point target;
	geometry social_space;
	geometry allowed_area <- world.shape;
	
	geometry home;
	
<<<<<<< Updated upstream
	reflex move when: social_space!=nil {
		if target=nil {target <- any_location_in(social_space union allowed_area);} 
		do goto target:target;
		if target distance_to self < 1#m {target <- nil; location <- target;}
=======
	reflex move when: not(state="I" and quarantine and (location overlaps home)) {
		if target=nil {
			list<geometry> buildings_in_allowed_area <- buildings_shapefile.contents where (each overlaps allowed_area);
			target <- any_location_in(one_of(buildings_in_allowed_area));
		}
		do goto target:target on: road_network;
		if target distance_to self < 1#m {
			target <- nil; 
			location <- target;
		}
>>>>>>> Stashed changes
	}
	
	reflex infect when:state="I" { 
		if quarantine {social_space <- nil;}
<<<<<<< Updated upstream
		ask people where (each.state="S") at_distance contact_distance { do infected; }
		if cycle-cycle_infect >= recover_after { state <- "R"; if quarantine {social_space <- world.shape;} }
=======
		ask people where (each.state="S") at_distance contact_dist { 
			do infected;
		}
		if cycle_recover <= cycle { 
			state <- "R"; 
			if quarantine {
				social_space <- world.shape;
			}
		}
>>>>>>> Stashed changes
	}
	
	action infected {
		if quarantine {target <- any_location_in(home);}
		state <- "I";
		cycle_recover <- cycle + truncated_gauss ({recover_after,15});
	}
	
	aspect default {
		draw cross(1) color:state_colors[state];
		draw circle(contact_distance) color:blend(state_colors[state],#transparent,0.1);
	}
	
}

experiment xp {
	output {
		display main {
<<<<<<< Updated upstream
=======
			graphics "Drawing buildings" {
      			loop building over: buildings_shapefile{
      				draw building color:#grey border:#black;
      			}
   			} 
   			graphics "Drawing roads" {
      			loop road over: roads_shapefile{
      				draw road color:#red;
      			}
   			}
   			graphics "Lockdown limits" {
      			loop s over: lspace{
      				draw s empty:true color:#blue;
      			}
   			}
>>>>>>> Stashed changes
			species people;
		}
		display chart {
			chart "state dynamic" type:series {
				loop stt over:["S","I","R"] {data stt value:people count (each.state=stt) color:state_colors[stt];}
			}
		}
	}
} 

experiment xplo type:batch repeat:20 
	until: people none_matches (each.state="I") {
		
	//parameter nb_people var:nb among:[100,500,1000,2000,5000];
	parameter social_distancing var:social_distancing among:[-1.0,0,5.0,20.0];
	parameter free_riders var:allowed_workers min:0.0 max:1.0 step:0.2;
	
	permanent {
		display main {
			chart "states" type:series x_serie_labels:string(social_distancing)+"\n"+string(with_precision(allowed_workers,1)) {
				data "Susceptible" value:mean(simulations collect (each.state_s)) color:state_colors["S"];
				data "Infected" value:mean(simulations collect (each.state_i)) color:state_colors["I"];
				data "Recovered" value:mean(simulations collect (each.state_r)) color:state_colors["R"];
			}
		}
	}
	
	reflex save_output {
		ask simulations {
			save [int(self),state_s,state_i,state_r] to:"../results/simple_explo" type:csv rewrite:false;
		}
	}
	
}

/**
* Name: SimpleSIR
* Based on ideas from https://www.washingtonpost.com/graphics/2020/world/corona-simulator/ 
* Author: kevinchapuis
* Tags: 
*/


model SimpleSIR

global {
	
	// Global
	int nb <- 500;
	float step <- 1#h;
	
	// Epidemic
	float contact_dist <- 2#m;
	float recover_after <- 10#day;
	float i_prop_start <- 0.05;
	
	// Policy
	float social_distancing <- -1.0 parameter:true among:[-1.0,0.0,5.0,10.0,20.0] category:"policy";
	float allowed_workers <- 0.2 parameter:true min:0.0 max:1.0 category:"policy";
	
	int time_after_realeasing_policies <- 0 parameter:true min:0 category:"policy";
	
	bool quarantine <- false parameter:true category:"policy";
	bool lockdown <- false parameter:true category:"policy";
	
	// Display
	map<string,rgb> state_colors <- ["S"::#green,"I"::#red,"R"::#blue];
	
	// Observer
	int state_s -> people count (each.state="S");
	int state_i -> people count (each.state="I");
	int state_r -> people count (each.state="R");
	
	// GIS data
	file buildings_shapefile <- file("../includes/buildings.shp");
	
	file roads_shapefile <- file("../includes/roads.shp");
	graph road_network;
	
	geometry shape <- envelope(buildings_shapefile);
	
	init {
		
		create building from:buildings_shapefile;
		road_network <- as_edge_graph(roads_shapefile);
		create people number:nb {
			home <- any(building); 
			work_schoolplace <- any(building);
			location <- any_location_in(home);
			agenda <- [rnd(7,9)::work_schoolplace,rnd(11,13)::nil,rnd(16,19)::nil,rnd(19,22)::home];
		}
		ask int(i_prop_start*nb) among people {do infected;}
		do define_social_space;
		
	}
	
	/*
	 * Define a personal zone of social contact for agent
	 * -1 = no social distancing
	 * 0 = perfect social distancing (no contact)
	 * 10 = a small area people can interact around them
	 */
	action define_social_space {
		list<people> free_riders <- (allowed_workers*nb) among people;
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
		list<geometry> lspace <- world.shape to_squares (4,false);
		ask people { allowed_area <- one_of(lspace); }
	}
	
	/*
	 * Releasing policy after "n" time step
	 */
	reflex realease_policy when:time_after_realeasing_policies > 0 and cycle = time_after_realeasing_policies {
		ask people { social_space <- world.shape; allowed_area <- world.shape; }
	}
	
}

species people skills:[moving] {
	
	// Epi
	string state <- "S" among:["S","I","R"];
	int cycle_infect;
	
	// Move
	point target;
	building building_target;
	geometry social_space;
	geometry allowed_area;
	
	// Agenda
	map<int,building> agenda;
	building home;
	building work_schoolplace;
	
	reflex move when: agenda.keys contains current_date.hour and social_space!=nil {
		building_target <- agenda[current_date.hour]=nil?any(building):agenda[current_date.hour];
		target <- target=nil?any_location_in(building_target):target; 
		do goto target:target on: road_network;
		if target=nil or location distance_to target < 5#m { target <- nil; do wander bounds:building_target; }
	}
	
	reflex infect when:state="I" { 
		if quarantine {social_space <- nil;}
		ask people where (each.state="S") at_distance contact_dist { do infected; }
		if (cycle-cycle_infect) * step >= recover_after { state <- "R"; if quarantine {social_space <- world.shape;} }
	}
	
	action infected {
		state <- "I";
		cycle_infect <- cycle;
	}
	
	aspect default {
		draw cross(1) color:state_colors[state];
		draw circle(contact_dist) color:blend(state_colors[state],#transparent,0.1);
	}
	
}

species building {
	string type;
	aspect default { draw shape color:#transparent border:#black;}
}

experiment xp {
	output {
		display main {
   			graphics "Drawing roads" {
      			loop road over: roads_shapefile{
      				draw road color:#red;
      			}
   			}
   			species building;
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

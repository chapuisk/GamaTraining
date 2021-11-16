/**
* Name: SimpleSIR3
* Based on the internal skeleton template. 
* Author: kevinchapuis
* Tags: 
*/

model SimpleSIR3

global {
	/** Insert the global definitions, variables and actions here */
	init {
		create people number:100;
	}
}

species people skills:[moving] {
	
	point target;
	
	reflex move {
		if target=nil {target <- any_location_in(world.shape);} 
		do goto target:target; 
		if target distance_to self < 1#m {target <- nil; location <- target;}
 	}
	
	aspect default {
		draw circle(1) color:#green;
	}
}

experiment NewModel1 type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display main {
			species people;
		}
	}
}

/**
* Name: SimpleSIR2
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags: 
*/


model SimpleSIR2

global {
	/** Insert the global definitions, variables and actions here */
	init {
		create people number:100;
	}
}

species people skills:[moving] {	
	
	reflex move {
		do wander;
	}
	
	aspect default {
		draw shape color:#green;
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


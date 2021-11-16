/**
* Name: SimpleSIR1
* Based on the internal skeleton template. 
* Author: kevinchapuis
* Tags: 
*/

model SimpleSIR1

global {
	/** Insert the global definitions, variables and actions here */
	init {
		create people number:100;
	}
}

species people {	
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

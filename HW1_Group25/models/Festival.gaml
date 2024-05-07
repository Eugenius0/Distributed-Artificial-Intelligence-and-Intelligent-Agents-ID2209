/**
* Name: Festival
* Based on the internal empty template. 
* Author: Dominika Drela, Eugen Lucchiari Hartz, Group 25
* Tags: 
*/


model Festival

/* Insert your model definition here */

global {
	int guestNumber <- 10;
	int foodStoreNumber <- 4;
	int drinkStoreNumber <- 4;
	int informationCenterNumber <- 1;
	point infoCenterLocation <- {40,40};
	int hungerRate <- 10;
	int infoCenterSize<- 5;
	float guestSpeed <- 0.5;
	
	init {
		create guest number:guestNumber;
		create foodStore number:foodStoreNumber;
		create drinkStore number:drinkStoreNumber;
		create infoCenterSp number:informationCenterNumber {
			location <- infoCenterLocation;
		}
	}
}

species guest skills:[moving] {
	
	float thirst<- rnd(50) + 50.0;
	float hunger<- rnd(50) + 50.0;
	
	rgb color<- #red;
	
	building target <- nil;
	
	aspect default {
		draw sphere(2) at: location color:color;
	}
	
	reflex thirstyOrHungry {
		thirst <- thirst-rnd(hungerRate);
		hunger <- hunger-rnd(hungerRate);
		
		bool getFood <- false;
		
		if(target=nil and (thirst < 30 or hunger < 30)){
			string destinationMessage <- name;
			if(thirst < 30 and hunger < 30) {
				destinationMessage <- destinationMessage + " is thirsty and hungry,";
			}
			else if(thirst < 30) {
				destinationMessage <- destinationMessage + " is thirsty,";
			}
			else if(hunger < 30) {
				destinationMessage <- destinationMessage + " is hungry,";
				getFood <- true;
			}
			color <- #blue;
			target <- one_of(infoCenterSp);
			
			destinationMessage <- destinationMessage + " heading to " + target.name;
			write destinationMessage;
		}
	}
	reflex beFestive when: target=nil {
		do wander;
		color<- #red;
	}
	reflex moveToTarget when: target!=nil {
		do goto target:target.location speed:guestSpeed;
	}
	reflex reachInfoCenter when: target!=nil and target.location = infoCenterLocation and location distance_to(target.location) < infoCenterSize {
		string destinationString <- name  + " getting "; 
		ask infoCenterSp at_distance infoCenterSize {
			if(myself.thirst <= myself.hunger) {
				myself.target <- drinkStores[rnd(length(drinkStores)-1)];
				myself.color <- #gold;
				destinationString <- destinationString + "drink at ";
			}
			else {
				myself.target <- foodStores[rnd(length(foodStores)-1)];
				myself.color <- #green;
				destinationString <- destinationString + "food at ";
			}
			write destinationString + myself.target.name;
		}
	}
	reflex isThisAStore when: target != nil and location distance_to(target.location) < 2 {
		ask target {
			string replenishString <- myself.name;	
			if(sellsFood = true) {
				myself.hunger <- 1000.0;
				myself.target<-nil;
				myself.color<- #red;
				replenishString <- replenishString + " ate food at " + name;
			}
			else if(sellsDrink = true) {
				myself.thirst <- 1500.0;
				myself.target<-nil;
				myself.color<- #red;
				replenishString <- replenishString + " had a drink at " + name;
			}
			
			write "replenish: " + replenishString;
		}
		target <- nil;
	}
}

species building {
	bool sellsFood<- false;
	bool sellsDrink<- false;	
} 

species infoCenterSp parent: building {
	list<foodStore> foodStores<- (foodStore at_distance 1000);
	list<drinkStore> drinkStores<- (drinkStore at_distance 1000);
	
	bool hasLocations <- false;
	
	reflex listStoreLocations when: hasLocations = false {
		ask foodStores {
			write "Food store at:" + location; 
		}
		ask drinkStores {
			write "Drink store at:" + location;
		}
		hasLocations <- true;
	}
	aspect default{
		draw cube(5) at: location color: #blue;
	}
}

species foodStore parent: building {
	bool sellsFood <- true;
	
	aspect default {
		draw pyramid(5) at: location color: #green;
	}
}

species drinkStore parent: building {
	bool sellsDrink <- true;
	
	aspect default {
		draw pyramid(5) at: location color: #gold;
	}
}

experiment Festival type:gui {
	output {
		display map type: opengl {
			species guest;
			species foodStore;
			species drinkStore;
			species infoCenterSp;
		}
	}
}


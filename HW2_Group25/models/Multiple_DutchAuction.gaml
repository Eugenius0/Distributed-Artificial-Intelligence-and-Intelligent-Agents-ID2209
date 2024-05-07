/***
* Name: MultipleDutchAuction
* Author: Dominika Drela, Eugen Lucchiari Hartz, Group 25
* Description: Challenge 1 - multiple Dutch auctions at the same time
***/

model MultipleDutchAuction

/* Insert your model definition here */
global {
	
	int guestNumber <- rnd(20)+20;
	
	float guestSpeed <- 0.5;
	
	
	point auctionMasterLocation <- {-10,50};
	list<string> itemsAvailable <- ["instruments","signed shirts","memorabillia", "posters and artwork"];
	
	// Time when auctioneers are created
	int auctionCreationMin <- 0;
	int auctionCreationMax <- 50;
	
	// Guest accepted price range min and max
	int guestAcceptedPriceMin <- 100;
	int guestAcceptedPriceMax <- 1500;
	
	// The initial price of the item to sell
	
	int dutchAuctionDecreaseMin <- 5;
	int dutchAuctionDecreaseMax <- 15;
	
	// The initial price of the item to sell, set above the max price so that no guest immediately wins
	int auctioneerDutchPriceMin <- 1504;
	int auctioneerDutchPriceMax <-1600;

	// Minimum price of the item, if the bids go below this the auction fails
	int minAuctionPrice <- 90;
	int maxAuctionPrice <- 300;
	
	list<string> auctionTypes <- ["Dutch"];

	
	
	init {
		/* Create guestNumber (defined above) amount of Guests */
		create Guest number: guestNumber
		{
			// Each guest prefers a random item
			preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];
		}
		
		create AuctionMaster
		{
			
		}
	}
	
}

species Guest skills:[moving, fipa] {
	// Default hunger vars
	
	bool wonAuction <- false;
	
	// Default color of guests
	rgb color <- #red;
	
	// This is the price at which the guest will buy merch, set in the configs above
	int guestMaxAcceptedPrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	Auctioneer targetAuction;
	Auctioneer target;
	
	string preferredItem;
	
	aspect default {
		draw sphere(2) at: location color: color;

		if (wonAuction = true) {
			if(preferredItem = "instruments") {
				color <- #purple;
			}
			else if(preferredItem = "signed shirts") {				
				color <- #orange;
			}
			else if(preferredItem = "memorabillia") {
				color <- #lime;
			}
			else if(preferredItem = "posters and artwork") {
				color <- #blue;
			}
		}
	}
	
	
	reflex inAuction when: targetAuction != nil {
		
		if(location distance_to(targetAuction.location) > 9) {
			target <- targetAuction;
		}
		else {
			target <- nil;
		}
	}
	

	reflex beIdle when: target = nil {
		do wander;
	}
	
	reflex moveToTarget when: target != nil {
		do goto target:target.location speed: guestSpeed;
	}
	

	reflex listen_messages when: (!empty(cfps)) {
		message requestFromInitiator <- (cfps at 0);
		// the request's format is as follows: [String, auctionType, soldItem, ...]
		if(requestFromInitiator.contents[0] = 'Start' and requestFromInitiator.contents[1] = preferredItem) {
			// If the guest receives a message from an auction selling its preferredItem,
			// the guest participates in that auction
			targetAuction <- requestFromInitiator.sender;

			// Send a message to the auctioneer telling them the guest will participate
			write name + " joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
			// TODO: handle this better
			// Essentially add the guest to the interestedGuests list
			targetAuction.interestedGuests <+ self;
		}
		//End of auction
		else if(requestFromInitiator.contents[0] = 'Stop') {
//			
			write name + ' knows the auction is over.';
			targetAuction <- nil;
			target <- nil;
			
		}
		
		else if(requestFromInitiator.contents[0] = 'Winner') {
			wonAuction <- true;
			write name + ' won the auction for ' + preferredItem;
			if(preferredItem = "posters and artwork") {
				write "Noiiiiice !!!";
			}
		}
	}
	
	
	reflex reply_messages when: (!empty(proposes)) {
		message requestFromInitiator <- (proposes at 0);
		// TODO: maybe define message contents somewhere, rn this works
		string auctionType <- requestFromInitiator.contents[1];
		if(auctionType = "Dutch") {
			int offer <- int(requestFromInitiator.contents[2]);
			if (guestMaxAcceptedPrice >= offer) {
				do accept_proposal with: (message: requestFromInitiator, contents: ["I, " + name + ", accept your offer of " + offer + ", merchant."]);
			}
			else {
				do reject_proposal (message: requestFromInitiator, contents: ["I, " + name + ", already have a house full of crap, you scoundrel!"]);	
				targetAuction <- nil;
				target <- nil;
			}
		}
	}
	
}
species AuctionMaster skills:[fipa] {
	bool auctioneersCreated <- false;
	list<Auctioneer> auctioneers <- [];

	reflex createAuctioneers when: !auctioneersCreated and time rnd(auctionCreationMin, auctionCreationMax) {
		string genesisString <- name + " creating auctions: ";
		
		loop i from: 0 to: length(itemsAvailable) - 1 {
			create Auctioneer {	
				location <- {rnd(100),rnd(100)};
				soldItem <- itemsAvailable[i];
				genesisString <- genesisString + name + " with " + itemsAvailable[i] + " ";
				myself.auctioneers <+ self;
			}
		}
		write genesisString;
		auctioneersCreated <- true;
	}	
}

species Auctioneer skills:[fipa, moving] {
	// Auction's initial size and color, location used in the beginning
	int mySize <- 10;
	rgb myColor <- #blueviolet;
	point targetLocation <- nil;
	
	// price of item to sell
	int auctioneerDutchPrice <- rnd(auctioneerDutchPriceMin, auctioneerDutchPriceMax);
	//int auctioneerEngPrice <- rnd(auctioneerEngPriceMin, auctioneerEngPriceMax);
	// minimum price of item to sell. if max bid is lower than this, bid is unsuccessful
	int auctioneerMinimumValue <- rnd(minAuctionPrice, maxAuctionPrice);
	
	// vars related to start and end of auction
	bool auctionRunning <- false;
	bool startAnnounced <- false;
	
	string auctionType <- auctionTypes[rnd(length(auctionTypes) - 1)];
	int currentBid <- 0;
	string currentWinner <- nil;
	message winner <- nil;

	// The kind of an item the merchant is selling
	string soldItem <- "";
	// The guests participating in the auction
	list<Guest> interestedGuests;

	aspect default {
		
		draw circle(mySize) color: myColor;
		//draw pyramid(mySize) color: myColor;
	}
	
	

	reflex sendStartAuction when: !auctionRunning and time >= 90 and targetLocation = nil and !startAnnounced {
		write name + " starting " + auctionType + " soon";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', soldItem]);
		startAnnounced <- true;
		
	}
	
	reflex guestsAreAround when: !auctionRunning and !empty(interestedGuests) and (interestedGuests max_of (location distance_to(each.location))) <= 13 {
		write name + " guestsAreAround";
		auctionRunning <- true;
	}

	reflex receiveAcceptMessages when: auctionRunning and !empty(accept_proposals) {
		if(auctionType = "Dutch") {
			write name + ' receives accept messages';
			
			loop a over: accept_proposals {
				write name + ' got accepted by ' + a.sender + ': ' + a.contents;
				do start_conversation (to: a.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
			}
			targetLocation <- auctionMasterLocation;
			auctionRunning <- false;
			//end of auction
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
			interestedGuests <- [];
			do die;
		}
	}


	reflex receiveRejectMessages when: auctionRunning and !empty(reject_proposals) {
		if(auctionType = "Dutch") {
			write name + ' receives reject messages';
			
			auctioneerDutchPrice <- auctioneerDutchPrice - rnd(dutchAuctionDecreaseMin, dutchAuctionDecreaseMax);
			if(auctioneerDutchPrice < auctioneerMinimumValue) {
				targetLocation <- auctionMasterLocation;
				auctionRunning <- false;

				write name + ' price went below minimum value (' + auctioneerMinimumValue + '). No more auction for thrifty guests!';
				do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
				interestedGuests <- [];
			}
		}

	}
	
	reflex sendAuctionInfo when: auctionRunning and time >= 50 and !empty(interestedGuests){
		if(auctionType = "Dutch") {
			write name + ' sends the offer of ' + auctioneerDutchPrice +' krona to participants';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: ['Buy my merch', auctionType, auctioneerDutchPrice]);
		}
//		
	}	
}// Auctioneer

experiment main type: gui {
	
	output {
		display map type: opengl {
			species Guest;
			species AuctionMaster;
			species Auctioneer;
		}
	}
}
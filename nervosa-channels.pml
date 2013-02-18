/*	nervosa-channels.pml
	author: peter mikitsh */

#define NC 4

mtype = {COFFEE, TEA};
chan request_cust_cash = [0] of {byte, chan, mtype}; //customer -> cashier request channel
chan request_cash_bar = [0] of {byte, chan, mtype}; //cashier -> barista request channel

active [NC] proctype Customer() {

byte rec_customerID;
chan customer = [0] of {byte, mtype};
mtype beverage, rec_beverage;

do
	::	// Enter Store; wait for cashier
		printf("CUSTOMER #%d: Enters store.\n", _pid);

		// Decide which beverage to order
		if
			:: true -> beverage = COFFEE;
			:: true -> beverage = TEA;
		fi;

		// Place Order
		printf("CUSTOMER #%d: Places order for %e.\n", _pid, beverage);
		request_cust_cash ! _pid, customer, beverage; 

		
		// Recieve Order
		customer ? rec_customerID, rec_beverage ->
			printf("CUSTOMER #%d: Exits store with %e.\n", rec_customerID, rec_beverage);
od;
}

active proctype Cashier() {

byte customerID;
chan customer;
mtype beverage;

do
	::	// Wait for a new customer
		printf("CASHIER: Wait for new customer.\n");
		// Select Customer
		request_cust_cash ? customerID, customer, beverage ->
			printf("CASHIER: Selected Customer #%d.\n", customerID);
			// Take Order
			printf("CASHIER: Take order from Customer #%d - %e.\n", customerID, beverage);
			// Send order to Barista
			printf("CASHIER: Pass Customer #%d's order to barista.\n", customerID);
			request_cash_bar ! customerID, customer, beverage;
od;
}

active [1] proctype Barista() {

byte customerID;
chan customer;
mtype beverage;

do
	::	// Wait for an order
		printf("BARISTA #%d: Waits for an order.\n", _pid);
		// Retrieve Order
		request_cash_bar ? customerID, customer, beverage ->
			printf("BARISTA #%d: Retrieves order for Customer #%d.\n", _pid, customerID);
			// Make Order
			printf("BARISTA #%d: Makes Customer #%d's order for %e.\n", _pid, customerID, beverage);
			// Deliver to the customer
			printf("BARISTA #%d: Delivers Customer #%d's order for %e.\n", _pid, customerID, beverage);
			customer ! customerID, beverage;
			
od;
}

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
		request_cust_cash ? customerID, customer, beverage ->
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
		request_cash_bar ? customerID, customer, beverage ->
			// Deliver to the customer
			printf("BARISTA #%d: Makes and delivers Customer #%d's order for %e.\n", _pid, customerID, beverage);
			customer ! customerID, beverage;
			
od;
}

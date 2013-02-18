/*	nervosa-channels.pml
	author: peter mikitsh */

#define NC 4


/*	Global Data Types
	request_cust_cash: customer -> cashier request channel
	request_cash_bar: cashier -> barista request channel
	bev: the beverage requested by the most recently processed customer (LTL use only)
	rec_bev: the beverage received by the most rececently processed customer (LTL use only)
	numOrders: Semaphore limiting at most one customer's order given to the cashier at a time
	numOrdersReceived: Number of orders that have been recieved by customers
	mtype: Beverages options at the cafe
	*/
chan request_cust_cash = [0] of {byte, chan, mtype};
chan request_cash_bar = [0] of {byte, chan, mtype};
mtype bev, rec_bev;
byte numOrders = 0;
byte numOrdersReceived;
mtype = {COFFEE, TEA};

/*	Customer: decides what beverage to order and sends a message to the cashier,
	placing the order. Waits to recieve a reply from the barista, and leaves the cafe
	once beverage is delivered to the customer.
	*/
active [NC] proctype Customer() {

/*	Local Data Types
	rec_customerID: the customer ID recieved from the barista
	customer: the channel for an instance of this Customer process
	beverage: the beverage the customer requested
	rec_beverage: the beverage the customer received from the barista
	*/
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
		atomic {
			numOrders == 0;
			numOrders++;
			request_cust_cash ! _pid, customer, beverage;
			
		}

		// Recieve Order
		customer ? rec_customerID, rec_beverage ->
			printf("CUSTOMER #%d: Exits store with %e.\n", rec_customerID, rec_beverage);

		atomic {
			numOrdersReceived++;
			bev = beverage;
			rec_bev = rec_beverage;
		}
od;
}

/*	Cashier: Takes a customer order and sends it to the barista. */
active proctype Cashier() {

/* Local data types
	customerID: The customer ID received from the customer.
	customer: A channel to the process from which the order was received.
	beverage: The beverage requested from the customer.
	*/
byte customerID;
chan customer;
mtype beverage;

do
	::	// Wait for a new customer
		printf("CASHIER: Wait for new customer.\n");
		// Select Customer
		atomic {
		request_cust_cash ? customerID, customer, beverage ->
			numOrders--;
			printf("CASHIER: Selected Customer #%d.\n", customerID);
			// Take Order
			printf("CASHIER: Take order from Customer #%d - %e.\n", customerID, beverage);
			// Send order to Barista
			printf("CASHIER: Pass Customer #%d's order to barista.\n", customerID);
			request_cash_bar ! customerID, customer, beverage;
			}
od;
}

/*	Barista: Retrieves orders, one at a time, from the cashier. The order is made and delivered
	to the customer using the embedded channel.
	*/
active [1] proctype Barista() {

/*	Local data types
	customerID: The customer ID for this order, received from the cashier
	customer: The channel representing the process of the Customer related to this order
	beverage: The beverage requested, recieved from the cashier
	*/
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

// Linear Temporal Logic

// #4: The baristas always give the correct drink to the customer whose order they are working on.
ltl SafetyDrink {
	[] (bev == rec_bev)
}

// #1: It's always the case that at most one customer is giving an order to the cashier.
ltl SafetyOrders {
	[] (numOrders <= 1)
}

// #3. It's always the case that eventually some customer receives a drink from a barista.
ltl LivenessOrderReceived {
	<> (numOrdersReceived > 0);
}
/*	nervosa-memory.pml
	author: peter mikitsh 
	notes: LTL verifications will return corrects iff:
		   - Settings > Max Depth is set to <=40.
		   - LivenessOrderPlaced can only be checked with NC set to <=2.
*/

#define NC 4
#define ARRAY_SIZE 10

/*	Order: Holds all state information regarding an order.
	customerID: the customer's process ID
	beverage: the drink requested by the customer
	fulfilled: true when the barista makes the order
	*/
typedef Order {
	byte customerID;
	mtype beverage;
	bool fulfilled;
}

mtype = {COFFEE, TEA};

/*	Customer-Cashier state
	tempOrderSem: Allows one customer to set global var's at a time
	placeOrderSem: Limits one customer to giving global state to the cashier
	tempCustomerID: The customer ID for the order to be submitted
	tempBeverage: The beverage choice for the order to be submitted
	cashierIndex: A write index that increments as the cashier fills the array
   */
bit tempOrderSem = 1;
bit placeOrderSem;
byte tempCustomerID;
mtype tempBeverage;
byte cashierIndex = 0;

/*	Cashier-Barista state
	orders[ARRAY_SIZE]: A permanent storage array for orders given to the cashier
	baristaIndex: The location in the array where the next order to be made is
	unfulfilledOrders: A count of orders in the array waiting to be made by baristas
	baristaOrderID_0: The ID of the customer barista 0 is working on (for LTL logic)
	baristaOrderID_1: The ID of the customer barista 1 is working on (for LTL logic)
	*/
Order orders[ARRAY_SIZE];
byte baristaIndex = 0;
byte unfulfilledOrders = 0;
byte baristaOrderID_0 = 0;
byte baristaOrderID_1 = 1;


/* Customer: Gets a location in the array, creates temporary variables
   for ID and beverage preferences, and notifies cashier when ready to
   place order.
   */
active [NC] proctype Customer() {
byte myIndex;
do
	::	// Enter Store; wait for cashier
		printf("CUSTOMER #%d: Enters store.\n", _pid);
		atomic {
		  tempOrderSem > 0;
		  tempOrderSem--;
     	}

		// Record new customer
		myIndex = cashierIndex;

		// Place order for coffee or tea
		tempCustomerID = _pid;
		if
			:: true -> tempBeverage = COFFEE;
			:: true -> tempBeverage = TEA;
		fi;
		printf("CUSTOMER #%d: Places order for %e.\n", _pid, tempBeverage);

		// notify cashier we're ready to place an order
		placeOrderSem++;

		// Wait for drink
		orders[myIndex].fulfilled == true;
		printf("CUSTOMER #%d: Exits store with %e.\n", _pid, orders[myIndex].beverage);
od;
}

/* Takes temporary customer variables and places them in permanent
   array storage. Notifies the Barista's of an available item to
   prepare using a semaphore.
   */
active proctype Cashier() {
do
	::	// Wait for a new customer
		printf("CASHIER: Wait for new customer.\n");
		
		atomic {
			placeOrderSem > 0;
			placeOrderSem--;

			printf("CASHIER: Selects customer.\n");

			// Record the order
			if
				:: cashierIndex + 1 < ARRAY_SIZE ->
					printf("CASHIER: Takes order.\n");
					orders[cashierIndex].customerID = tempCustomerID;
					orders[cashierIndex].beverage = tempBeverage;
					printf("CASHIER: Pass Customer #%d's order to barista.\n",
												orders[cashierIndex].customerID);
					unfulfilledOrders++;
					cashierIndex++;
					tempOrderSem++;
			fi;
     	}
		
od;
}

/* Stores the customer ID's of orders currently being fulfilled in global memory.
   Marks orders as fulfilled so the customer can leave the cafe.
   */
active [2] proctype Barista() {
byte myOrder;
do
	::	// Wait for an order
		printf("BARISTA #%d: Waits for an order.\n", _pid);
		atomic {
			unfulfilledOrders > 0;
			unfulfilledOrders--;
		}

		// Retrieve order
		atomic {
			myOrder = baristaIndex;
			baristaIndex++;
			if
				:: _pid % 2 == 0 -> baristaOrderID_0 = orders[myOrder].customerID;
				:: _pid % 2 == 1 -> baristaOrderID_1 = orders[myOrder].customerID;
			fi;
		}
		printf("BARISTA #%d: Retrieves Customer #%d's order for %e.\n",
					_pid, orders[myOrder].customerID, orders[myOrder].beverage);

		// Make order
		printf("BARISTA #%d: Makes Customer #%d's order.\n",
												_pid, orders[myOrder].customerID);

		// Deliver order
		printf("BARISTA #%d: Deliver Customer #%d's order.\n",
												_pid, orders[myOrder].customerID);

		orders[myOrder].fulfilled = true;

od;
}


// LINEAR TEMPORAL LOGIC

// #1: only one customer (at a time) placing an order
ltl SafetyOrder {
	[] (placeOrderSem <= 1);
}

// #3: The baristas never work on the same order at the same time.
ltl SafetyNoTwoSameCustomers {
	[] (baristaOrderID_0 != baristaOrderID_1)
}

// #1 Eventually some customer can place an order with the cashier.
ltl LivenessOrderPlaced {
	<> (placeOrderSem > 0);
}
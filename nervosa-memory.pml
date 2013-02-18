/*	nervosa-memory.pml
	author: peter mikitsh */

#define NC 4
#define ARRAY_SIZE 10

typedef Order {
	byte customerID;
	mtype beverage;
	bool fulfilled;
}

mtype = {COFFEE, TEA};

// Customer-Cashier state
byte tempOrderSem = 1;
byte placeOrderSem = 0;
byte tempCustomerID;
mtype tempBeverage;
byte cashierIndex = 0;

// Cashier-Barista state
Order orders[ARRAY_SIZE];
byte baristaIndex = 0;
byte unfulfilledOrders = 0;

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

ltl Safety {
	[] (placeOrderSem <= 1) // #1: only one customer (at a time) placing an order
}

ltl Liveness {
	<> (placeOrderSem > 0) // #1 Eventually some customer can place an order with the cashier.
}
/*	nervosa-memory.pml
	author: peter mikitsh */

#define NC 2

typedef Order {
	byte customerID;
	mtype beverage;
	bool fulfilled;
}

mtype = {COFFEE, TEA, NONE};

// Customer-Cashier state
bit tempOrderSem = 1;
bit placeOrderSem = 0;
byte tempCustomerID;
mtype tempBeverage;
byte cashierIndex = 0;

// Cashier-Barista state
Order orders[20];
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

		// Record the order
		orders[cashierIndex].customerID = tempCustomerID;
		orders[cashierIndex].beverage = tempBeverage;
		
		// Pass the order to barista
		printf("CASHIER: Pass Customer #%d's order to barista.\n", orders[cashierIndex].customerID);
		
		unfulfilledOrders++;
		cashierIndex++;
		tempOrderSem++;
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

		// Make and deliver order
		printf("BARISTA #%d: Makes and delivers Customer #%d's order.\n",
												_pid, orders[myOrder].customerID);

		orders[myOrder].fulfilled = true;

od;
}
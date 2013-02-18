/*	nervosa-memory.pml
	author: peter mikitsh 
	notes: LTL verifications will return corrects iff Settings > Max Depth is set to <=40.
		   LivenessOrderPlaced can only be checked with NC set to <=2.
*/

#define NC 4
#define ARRAY_SIZE 10

typedef Order {
	byte customerID;
	mtype beverage;
	bool fulfilled;
}

mtype = {COFFEE, TEA};

// Customer-Cashier state
bit tempOrderSem = 1;
bit placeOrderSem;
byte tempCustomerID;
mtype tempBeverage;
byte cashierIndex = 0;

// Cashier-Barista state
Order orders[ARRAY_SIZE];
byte baristaIndex = 0;
byte unfulfilledOrders = 0;
byte baristaOrderID_0 = 0;
byte baristaOrderID_1 = 1;

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
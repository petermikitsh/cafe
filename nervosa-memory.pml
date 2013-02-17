/*	nervosa-memory-newdesign.pml
	author: peter mikitsh */

#define NC 2

typedef Order {
	byte customerID;
	mtype beverage;
	bool fulfilled;
	bool received;
}

mtype = {COFFEE, TEA, NONE};

// Customer-Cashier state
bit cashierSem = 1;
byte tempCustomerID;
mtype tempBeverage;
bool orderReady;
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
		  cashierSem > 0;
		  cashierSem--;
     	}

		// Record new customer
		myIndex = cashierIndex;

		// Place order for coffee or tea
		tempCustomerID = _pid;
		if
			:: _pid % 2 == 0 ->
					printf("CUSTOMER #%d: Places order for COFFEE.\n", _pid);
					tempBeverage = COFFEE;
			:: _pid % 2 == 1 ->
					printf("CUSTOMER #%d: Places order for TEA.\n", _pid);
					tempBeverage = TEA;
		fi;

		// notify cashier we're ready to place an order
		orderReady = true;

		// wait for transaction to be recorded and release the cashier
		orders[myIndex].received == true;
		cashierSem++;

		// Wait for drink
		orders[myIndex].fulfilled == true;
		printf("CUSTOMER #%d: Exits store with drink.\n", _pid);

od;
}

active [1] proctype Cashier() {
do
	::	// Wait for a new customer
		printf("CASHIER: Wait for new customer.\n");
		orderReady == true;

		// Record the order
		orders[cashierIndex].customerID = tempCustomerID;
		orders[cashierIndex].beverage = tempBeverage;
		orders[cashierIndex].fulfilled = false;
		orders[cashierIndex].received = true;
		cashierIndex++;
		
		// Pass the order to barista
		printf("CASHIER: Pass order to barista.\n");
		unfulfilledOrders++;

		// Wait for the next order
		orderReady = false;
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
		if
			:: orders[myOrder].beverage == TEA ->
					printf("BARISTA #%d: Retrieves Customer #%d's order for TEA.\n", _pid, orders[myOrder].customerID);
			:: orders[myOrder].beverage == COFFEE ->
					printf("BARISTA #%d: Retrieves Customer #%d's order for COFFEE.\n", _pid, orders[myOrder].customerID);
		fi;

		// Make and deliver order
		printf("BARISTA #%d: Makes and delivers order.\n", _pid);
		orders[myOrder].fulfilled = true;

od;
}
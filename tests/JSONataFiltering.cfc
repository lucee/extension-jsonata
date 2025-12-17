component extends="org.lucee.cfml.test.LuceeTestCase" labels="jsonata" {

	function run( testResults, testBox ) {

		describe( "JSONata filtering", function() {

			it( "filters array by condition", function() {
				var data = {
					products: [
						{ name: "apple", price: 1.50 },
						{ name: "banana", price: 0.75 },
						{ name: "cherry", price: 3.00 }
					]
				};
				var result = JSONata( "products[price > 1].name", data );
				expect( result ).toBeArray();
				expect( result ).toHaveLength( 2 );
				expect( result ).toInclude( "apple" );
				expect( result ).toInclude( "cherry" );
			});

			it( "filters with equality", function() {
				var data = {
					orders: [
						{ id: 1, status: "complete" },
						{ id: 2, status: "pending" },
						{ id: 3, status: "complete" }
					]
				};
				var result = JSONata( "orders[status='complete'].id", data );
				expect( result ).toBeArray();
				expect( result ).toHaveLength( 2 );
			});

		});

	}

}

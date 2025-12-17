component extends="org.lucee.cfml.test.LuceeTestCase" labels="jsonata" {

	function run( testResults, testBox ) {

		describe( "JSONata transformations", function() {

			it( "transforms to new structure", function() {
				var data = { firstName: "Zac", lastName: "Spitzer" };
				var result = JSONata( '{ "fullName": firstName & " " & lastName }', data );
				expect( result ).toBeStruct();
				expect( result ).toHaveKey( "fullName" );
				expect( result.fullName ).toBe( "Zac Spitzer" );
			});

			it( "uses $uppercase", function() {
				var data = { name: "hello world" };
				var result = JSONata( "$uppercase(name)", data );
				expect( result ).toBe( "HELLO WORLD" );
			});

			it( "uses $lowercase", function() {
				var data = { name: "HELLO WORLD" };
				var result = JSONata( "$lowercase(name)", data );
				expect( result ).toBe( "hello world" );
			});

		});

		describe( "JSONata null handling", function() {

			it( "returns empty string for missing path", function() {
				var data = { name: "Zac" };
				var result = JSONata( "missing", data );
				expect( result ).toBe( "" );
			});

			it( "returns empty string for empty result", function() {
				var data = { items: [] };
				var result = JSONata( "items[0]", data );
				expect( result ).toBe( "" );
			});

		});

		describe( "JSONata complex queries", function() {

			it( "handles nested paths", function() {
				var data = {
					user: {
						profile: {
							address: {
								city: "Sydney"
							}
						}
					}
				};
				var result = JSONata( "user.profile.address.city", data );
				expect( result ).toBe( "Sydney" );
			});

			it( "handles array of objects with aggregation", function() {
				var data = {
					orders: [
						{ product: "A", quantity: 2, price: 10 },
						{ product: "B", quantity: 1, price: 25 },
						{ product: "A", quantity: 3, price: 10 }
					]
				};
				var result = JSONata( "$sum(orders.(quantity * price))", data );
				expect( result ).toBe( 75 );
			});

		});

	}

}

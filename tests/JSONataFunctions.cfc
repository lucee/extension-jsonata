component extends="org.lucee.cfml.test.LuceeTestCase" labels="jsonata" {

	function run( testResults, testBox ) {

		describe( "JSONata custom functions", function() {

			it( "calls single-arg custom function", function() {
				var data = { price: 42.5 };
				var result = JSONata(
					"$formatprice(price)",
					data,
					{},
					{
						functions: {
							formatPrice: function( val ) {
								return "$" & numberFormat( val, ",.00" );
							}
						}
					}
				);
				expect( result ).toBe( "$42.50" );
			});

			it( "calls no-arg custom function", function() {
				var result = JSONata(
					"$getgreeting()",
					{},
					{},
					{
						functions: {
							getGreeting: function() {
								return "Hello World";
							}
						}
					}
				);
				expect( result ).toBe( "Hello World" );
			});

			it( "calls multi-arg custom function", function() {
				var data = { a: 10, b: 3 };
				var result = JSONata(
					"$mymod(a, b)",
					data,
					{},
					{
						functions: {
							myMod: function( x, y ) {
								return x % y;
							}
						}
					}
				);
				expect( result ).toBe( 1 );
			});

			it( "custom function returns struct", function() {
				var data = { name: "Zac", age: 42 };
				var result = JSONata(
					"$makeuser(name, age)",
					data,
					{},
					{
						functions: {
							makeUser: function( n, a ) {
								return { username: n, years: a, isAdmin: false };
							}
						}
					}
				);
				expect( result ).toBeStruct();
				expect( result.username ).toBe( "Zac" );
				expect( result.years ).toBe( 42 );
				expect( result.isAdmin ).toBe( false );
			});

			it( "custom function with bindings", function() {
				var data = { value: 100 };
				var result = JSONata(
					"$calc(value) + $offset",
					data,
					{ offset: 5 },
					{
						functions: {
							calc: function( v ) {
								return v * 2;
							}
						}
					}
				);
				expect( result ).toBe( 205 );
			});

			it( "custom function with timeout", function() {
				var data = { value: 10 };
				var result = JSONata(
					"$double(value)",
					data,
					{},
					{
						timeout: 5000,
						functions: {
							double: function( v ) {
								return v * 2;
							}
						}
					}
				);
				expect( result ).toBe( 20 );
			});

		});

	}

}

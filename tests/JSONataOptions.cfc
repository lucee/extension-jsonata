component extends="org.lucee.cfml.test.LuceeTestCase" labels="jsonata" {

	function run( testResults, testBox ) {

		describe( "JSONata timeout and safety options", function() {

			it( "allows normal execution with options", function() {
				var data = { values: [ 1, 2, 3, 4, 5 ] };
				var result = JSONata( "$sum(values)", data, {}, { timeout: 5000, maxDepth: 100 } );
				expect( result ).toBe( 15 );
			});

			it( "throws on max depth exceeded", function() {
				// Recursive function that exceeds depth limit
				var expr = "(
					$a := function(){ $b() };
					$b := function(){ $c() };
					$c := function(){ $a() };
					$a()
				)";
				expect( function() {
					JSONata( expr, {}, {}, { timeout: 5000, maxDepth: 5 } );
				}).toThrow();
			});

			it( "throws on timeout exceeded", function() {
				// Expression that takes too long - infinite recursion
				var expr = "(
					$loop := function(){ $loop() };
					$loop()
				)";
				expect( function() {
					JSONata( expr, {}, {}, { timeout: 100, maxDepth: 1000 } );
				}).toThrow();
			});

			it( "works with bindings and options together", function() {
				var data = { value: 10 };
				var result = JSONata( "value * $multiplier", data, { multiplier: 5 }, { timeout: 5000 } );
				expect( result ).toBe( 50 );
			});

			it( "works with empty bindings and options", function() {
				var data = { name: "Zac" };
				var result = JSONata( "name", data, {}, {} );
				expect( result ).toBe( "Zac" );
			});

		});

	}

}

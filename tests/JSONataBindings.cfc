component extends="org.lucee.cfml.test.LuceeTestCase" labels="jsonata" {

	function run( testResults, testBox ) {

		describe( "JSONata variable bindings", function() {

			it( "uses simple variable binding", function() {
				var data = { name: "World" };
				var result = JSONata( "$greeting & ' ' & name", data, { greeting: "Hello" } );
				expect( result ).toBe( "Hello World" );
			});

			it( "uses multiple variable bindings", function() {
				var data = { value: 10 };
				var result = JSONata( "value * $multiplier + $offset", data, { multiplier: 5, offset: 3 } );
				expect( result ).toBe( 53 );
			});

			it( "uses array variable binding", function() {
				var data = { multiplier: 2 };
				// Bind an array as variable
				var result = JSONata( "$sum($values) * multiplier", data, { values: [ 1, 2, 3 ] } );
				// (1 + 2 + 3) * 2 = 12
				expect( result ).toBe( 12 );
			});

			it( "uses struct as variable value", function() {
				var data = { items: [ 1, 2, 3 ] };
				var result = JSONata( "$config.prefix & $string($sum(items))", data, { config: { prefix: "Total: " } } );
				expect( result ).toBe( "Total: 6" );
			});

			it( "works without bindings (null)", function() {
				var data = { name: "Zac" };
				var result = JSONata( "name", data, {} );
				expect( result ).toBe( "Zac" );
			});

		});

	}

}

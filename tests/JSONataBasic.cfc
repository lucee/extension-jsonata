component extends="org.lucee.cfml.test.LuceeTestCase" labels="jsonata" {

	function run( testResults, testBox ) {

		describe( "JSONata basic queries", function() {

			it( "evaluates simple path expression against struct", function() {
				var data = { name: "Zac", age: 42 };
				var result = JSONata( "name", data );
				expect( result ).toBe( "Zac" );
			});

			it( "evaluates simple path expression against JSON string", function() {
				var json = '{"name":"Zac","age":42}';
				var result = JSONata( "name", json );
				expect( result ).toBe( "Zac" );
			});

			it( "evaluates $sum on array", function() {
				var data = { a: 1, b: 2, c: [ 1, 2, 3, 4, 5 ] };
				var result = JSONata( "$sum(c)", data );
				expect( result ).toBe( 15 );
			});

			it( "evaluates $count on array", function() {
				var data = { items: [ "a", "b", "c", "d" ] };
				var result = JSONata( "$count(items)", data );
				expect( result ).toBe( 4 );
			});

			it( "evaluates $average on array", function() {
				var data = { scores: [ 10, 20, 30, 40 ] };
				var result = JSONata( "$average(scores)", data );
				expect( result ).toBe( 25 );
			});

		});

	}

}

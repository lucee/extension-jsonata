# Lucee Extension JSONata

Query and transform JSON data using [JSONata](https://jsonata.org) expressions - like XPath/XQuery but for JSON.

**Requires Lucee 7.0.3+** — uses maven-based classloading (no OSGi).

## Basic Queries

```cfml
// Simple path
data = { name: "Zac", age: 42 };
JSONata( "name", data )  // "Zac"

// Works with JSON strings too
JSONata( "name", '{"name":"Zac","age":42}' )  // "Zac"

// Nested paths
data = { user: { profile: { city: "Sydney" } } };
JSONata( "user.profile.city", data )  // "Sydney"
```

## Aggregations

```cfml
data = { values: [ 1, 2, 3, 4, 5 ] };

JSONata( "$sum(values)", data )      // 15
JSONata( "$average(values)", data )  // 3
JSONata( "$count(values)", data )    // 5
JSONata( "$min(values)", data )      // 1
JSONata( "$max(values)", data )      // 5
```

## Filtering

```cfml
data = {
    products: [
        { name: "apple", price: 1.50 },
        { name: "banana", price: 0.75 },
        { name: "cherry", price: 3.00 }
    ]
};

// Filter by condition
JSONata( "products[price > 1].name", data )  // ["apple", "cherry"]

// First match
JSONata( "products[price < 1]", data )  // { name: "banana", price: 0.75 }
```

## Transformations

```cfml
data = { firstName: "Zac", lastName: "Spitzer" };

// String concatenation
JSONata( 'firstName & " " & lastName', data )  // "Zac Spitzer"

// Build new structure
JSONata( '{ "fullName": firstName & " " & lastName }', data )
// { fullName: "Zac Spitzer" }

// String functions
JSONata( "$uppercase(firstName)", data )  // "ZAC"
JSONata( "$lowercase(lastName)", data )   // "spitzer"
```

## Complex Queries

```cfml
data = {
    orders: [
        { product: "A", quantity: 2, price: 10 },
        { product: "B", quantity: 1, price: 25 },
        { product: "A", quantity: 3, price: 10 }
    ]
};

// Calculate total
JSONata( "$sum(orders.(quantity * price))", data )  // 75
```

## Variable Bindings

Pass variables accessible via `$varName` in expressions.

```cfml
// Simple variable
data = { name: "World" };
JSONata( "$greeting & ' ' & name", data, { greeting: "Hello" } )  // "Hello World"

// Multiple variables
data = { value: 10 };
JSONata( "value * $multiplier + $offset", data, { multiplier: 5, offset: 3 } )  // 53

// Array as variable
data = { multiplier: 2 };
JSONata( "$sum($values) * multiplier", data, { values: [ 1, 2, 3 ] } )  // 12

// Struct as variable
data = { items: [ 1, 2, 3 ] };
JSONata( "$config.prefix & $string($sum(items))", data, { config: { prefix: "Total: " } } )  // "Total: 6"
```

## Timeout and Safety Options

Protect against runaway expressions with timeout and recursion depth limits.

```cfml
// With timeout (milliseconds) and max recursion depth
JSONata( expression, data, {}, { timeout: 5000, maxDepth: 50 } )

// Throws error if expression exceeds limits
// - timeout: "Expression evaluation timeout: Check for infinite loop"
// - maxDepth: "Stack overflow error: Check for non-terminating recursive function..."
```

| Option | Default | Description |
| ------ | ------- | ----------- |
| `timeout` | 5000ms | Maximum evaluation time |
| `maxDepth` | 100 | Maximum recursion depth |

## Custom Functions

Register CFML closures as custom JSONata functions.

```cfml
// Single-arg function - use lowercase in expression
data = { price: 42.5 };
JSONata(
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
)  // "$42.50"

// Multi-arg function
data = { name: "Zac", age: 42 };
JSONata(
    "$makeuser(name, age)",
    data,
    {},
    {
        functions: {
            makeUser: function( n, a ) {
                return { username: n, years: a };
            }
        }
    }
)  // { username: "Zac", years: 42 }

// Combine with bindings and timeout
JSONata(
    "$calc(value) + $offset",
    { value: 100 },
    { offset: 5 },
    {
        timeout: 5000,
        functions: {
            calc: function( v ) { return v * 2; }
        }
    }
)  // 205
```

**Note:** Use lowercase function names in expressions (e.g., `$formatprice`) since CFML uppercases struct keys.

## Function Signature

```cfml
result = JSONata( expression, data [, bindings [, options]] )
```

| Argument | Description |
| -------- | ----------- |
| `expression` | JSONata query/transform expression (required) |
| `data` | CFML struct/array or JSON string (required) |
| `bindings` | Struct of variables accessible via `$varName` |
| `options` | Struct: `timeout`, `maxDepth`, `functions` |

## Requirements

- Lucee 7.0.3+
- Java 11 or later

## Technical Details

Uses [dashjoin/jsonata-java](https://github.com/dashjoin/jsonata-java) (zero external dependencies).

Maven-based extension using embedded `/maven/` repo layout with `maven=` attribute in the FLD. No OSGi bundles.

Full expression syntax: https://docs.jsonata.org

## License

LGPL 2.1

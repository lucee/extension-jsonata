package org.lucee.extension.jsonata;

import static com.dashjoin.jsonata.Jsonata.jsonata;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.dashjoin.jsonata.JException;
import com.dashjoin.jsonata.Jsonata;
import com.dashjoin.jsonata.Jsonata.Frame;
import com.dashjoin.jsonata.Jsonata.JFunction;
import com.dashjoin.jsonata.Jsonata.JFunctionCallable;
import com.dashjoin.jsonata.json.Json;

import lucee.loader.engine.CFMLEngine;
import lucee.loader.engine.CFMLEngineFactory;
import lucee.runtime.PageContext;
import lucee.runtime.exp.PageException;
import lucee.runtime.ext.function.BIF;
import lucee.runtime.type.Array;
import lucee.runtime.type.Struct;
import lucee.runtime.type.UDF;

/**
 * JSONata - Query and transform JSON data using JSONata expressions.
 *
 * Usage:
 *   result = JSONata( "$sum(c)", '{"a":1,"b":2,"c":[1,2,3,4,5]}' )
 *   result = JSONata( "name", { name: "Zac", age: 42 } )
 *   result = JSONata( "$greeting & ' ' & name", data, { greeting: "Hello" } )
 *   result = JSONata( expr, data, {}, { timeout: 5000, maxDepth: 50 } )
 *
 * See https://jsonata.org for expression syntax.
 */
public class JSONata extends BIF {

	private static final long serialVersionUID = 1L;

	// Default runtime bounds
	private static final long DEFAULT_TIMEOUT = 5000L;
	private static final int DEFAULT_MAX_DEPTH = 100;

	public static Object call( PageContext pc, String expression, Object data ) throws PageException {
		return call( pc, expression, data, null, null );
	}

	public static Object call( PageContext pc, String expression, Object data, Struct bindings ) throws PageException {
		return call( pc, expression, data, bindings, null );
	}

	public static Object call( PageContext pc, String expression, Object data, Struct bindings, Struct options ) throws PageException {
		try {
			CFMLEngine eng = CFMLEngineFactory.getInstance();

			// Parse expression
			Jsonata expr = jsonata( expression );

			// Convert CFML data to native Java types (Map/List)
			Object javaData = toJavaObject( data );

			// Create frame from expression (required for runtime bounds to work)
			Frame frame = expr.createFrame();

			// Set up bindings if provided
			if ( bindings != null && bindings.size() > 0 ) {
				for ( Object keyObj : bindings.keySet() ) {
					String key = String.valueOf( keyObj );
					Object value = bindings.get( key, null );
					// JSONata is case-sensitive, CFML struct keys are uppercased
					// Bind both original and lowercase versions
					frame.bind( key, toJavaObject( value ) );
					frame.bind( key.toLowerCase(), toJavaObject( value ) );
				}
			}

			// Set up options if provided
			if ( options != null && options.size() > 0 ) {
				// Runtime bounds
				long timeout = DEFAULT_TIMEOUT;
				int maxDepth = DEFAULT_MAX_DEPTH;
				boolean hasRuntimeBounds = false;

				Object timeoutVal = options.get( "timeout", null );
				if ( timeoutVal == null ) timeoutVal = options.get( "TIMEOUT", null );
				if ( timeoutVal != null ) {
					timeout = eng.getCastUtil().toLongValue( timeoutVal );
					hasRuntimeBounds = true;
				}

				Object maxDepthVal = options.get( "maxDepth", null );
				if ( maxDepthVal == null ) maxDepthVal = options.get( "MAXDEPTH", null );
				if ( maxDepthVal == null ) maxDepthVal = options.get( "maxdepth", null );
				if ( maxDepthVal != null ) {
					maxDepth = eng.getCastUtil().toIntValue( maxDepthVal );
					hasRuntimeBounds = true;
				}

				if ( hasRuntimeBounds ) {
					frame.setRuntimeBounds( timeout, maxDepth );
				}

				// Custom functions
				Object functionsVal = options.get( "functions", null );
				if ( functionsVal == null ) functionsVal = options.get( "FUNCTIONS", null );
				if ( functionsVal != null ) {
					Struct functions = eng.getCastUtil().toStruct( functionsVal );
					registerCustomFunctions( pc, eng, expr, frame, functions );
				}
			}

			// Evaluate
			Object result = expr.evaluate( javaData, frame );

			// Convert back to CFML types
			return toCFMLObject( eng, result );
		}
		catch ( JException je ) {
			// Convert JSONata exceptions to PageException with clear message
			throw CFMLEngineFactory.getInstance().getCastUtil().toPageException( je );
		}
		catch ( PageException pe ) {
			throw pe;
		}
		catch ( Exception e ) {
			throw CFMLEngineFactory.getInstance().getCastUtil().toPageException( e );
		}
	}

	/**
	 * Register CFML closures/UDFs as JSONata custom functions
	 */
	private static void registerCustomFunctions( PageContext pc, CFMLEngine eng, Jsonata expr, Frame frame, Struct functions ) throws PageException {
		for ( Object keyObj : functions.keySet() ) {
			String funcName = String.valueOf( keyObj );
			Object funcVal = functions.get( funcName, null );

			if ( !( funcVal instanceof UDF ) ) {
				throw eng.getExceptionUtil().createApplicationException(
					"Custom function '" + funcName + "' must be a closure or UDF" );
			}

			UDF udf = (UDF) funcVal;

			// Create a JFunctionCallable that bridges to CFML
			JFunctionCallable callable = ( input, args ) -> {
				try {
					// Convert args from Java List to CFML Array
					Array cfmlArgs = eng.getCreationUtil().createArray();
					if ( args != null ) {
						for ( Object arg : (List<?>) args ) {
							cfmlArgs.append( toCFMLObject( eng, arg ) );
						}
					}
					// Call the CFML function
					Object result = udf.call( pc, cfmlArgs.toArray(), true );
					// Convert result back to Java types
					return toJavaObject( result );
				}
				catch ( PageException pe ) {
					throw new RuntimeException( pe );
				}
			};

			// Register lowercase - JSONata is case-sensitive
			JFunction jfunc = new JFunction( callable, null );
			expr.registerFunction( funcName.toLowerCase(), jfunc );
		}
	}

	/**
	 * Convert CFML types to Java Map/List for jsonata
	 */
	private static Object toJavaObject( Object data ) {
		if ( data instanceof String ) {
			String str = (String) data;
			str = str.trim();
			// Only parse if it looks like JSON (object or array)
			if ( ( str.startsWith( "{" ) && str.endsWith( "}" ) ) ||
			     ( str.startsWith( "[" ) && str.endsWith( "]" ) ) ) {
				return Json.parseJson( str );
			}
			// Plain string value - return as-is
			return str;
		}
		// CFML Struct implements Map, Array implements List
		// So they should work directly with jsonata
		return data;
	}

	/**
	 * Convert Java result back to CFML types
	 */
	private static Object toCFMLObject( CFMLEngine eng, Object result ) throws PageException {
		if ( result == null ) {
			return "";
		}
		// Simple types pass through
		if ( result instanceof String || result instanceof Number || result instanceof Boolean ) {
			return result;
		}
		// Already a CFML type
		if ( result instanceof Struct || result instanceof Array ) {
			return result;
		}
		// Java Map - convert to Struct
		if ( result instanceof Map ) {
			Struct struct = eng.getCreationUtil().createStruct();
			Map<?, ?> map = (Map<?, ?>) result;
			for ( Map.Entry<?, ?> entry : map.entrySet() ) {
				struct.set( String.valueOf( entry.getKey() ), toCFMLObject( eng, entry.getValue() ) );
			}
			return struct;
		}
		// Java List - convert to Array
		if ( result instanceof List ) {
			Array arr = eng.getCreationUtil().createArray();
			List<?> list = (List<?>) result;
			for ( Object item : list ) {
				arr.append( toCFMLObject( eng, item ) );
			}
			return arr;
		}
		// Fallback
		return result;
	}

	@Override
	public Object invoke( PageContext pc, Object[] args ) throws PageException {
		CFMLEngine eng = CFMLEngineFactory.getInstance();

		if ( args.length < 2 ) {
			throw eng.getExceptionUtil()
				.createFunctionException( pc, "JSONata", 2, "data", "Both expression and data are required", null );
		}

		String expression = eng.getCastUtil().toString( args[0] );
		Object data = args[1];
		Struct bindings = null;
		Struct options = null;

		if ( args.length >= 3 && args[2] != null ) {
			bindings = eng.getCastUtil().toStruct( args[2] );
		}

		if ( args.length >= 4 && args[3] != null ) {
			options = eng.getCastUtil().toStruct( args[3] );
		}

		return call( pc, expression, data, bindings, options );
	}
}

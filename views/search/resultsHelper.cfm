<cfscript>
	function truncate( required string text, numeric stop=250, string clamp="...", string delimiter="" ) {
		var exploded = listToArray( trim( arguments.text ), arguments.delimiter );
		if( exploded.len() < arguments.stop ){ arguments.clamp = ""; }
		return exploded
					.filter( function( item, index ){ return index <= stop; } )
					.toList( arguments.delimiter ) & arguments.clamp;
    }

	/**
	 * utility to strip HTML
	 */
	function stripHTML( stringTarget ){
		return reReplaceNoCase( reReplaceNoCase( arguments.stringTarget, "<[^>]*>", "", "ALL" ), "{{{[^}]*}}}", "", "ALL" );
	}
	/**
	 * Utility function to help you highlight search terms in content
	 * @term The search term
	 * @content The content searched
	 */
	function highlightSearchTerm( required term, required content ){
		var match   = findNoCase( arguments.term, arguments.content );
		if( !findNoCase( arguments.term, arguments.content ) ){
			return arguments.content;
		}

		try {
			return reReplaceNoCase(
				excerpt,
				"(#arguments.term#)",
				"<span class='highlight'>\1</span>",
				"all"
			);
		} catch ( Any e ) {
			return arguments.content;
		}

	}

</cfscript>
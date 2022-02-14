<cfscript>
	function truncate( required string text, numeric stop=250, string clamp="...", string delimiter="" ) {
		var exploded = listToArray( text, delimiter );
		if( exploded.len() >= stop ) arguments.clamp = "";
		return exploded
					.filter( function( item, index ){ return index <= stop; } )
					.toList( delimiter ) & clamp;
    }

	/**
	 * utility to strip HTML
	 */
	function stripHTML( stringTarget ){
		return reReplaceNoCase( arguments.stringTarget, "<[^>]*>", "", "ALL" );
	}
	/**
	 * Utility function to help you highlight search terms in content
	 * @term The search term
	 * @content The content searched
	 */
	function highlightSearchTerm( required term, required content ){
		var match   = findNoCase( arguments.term, arguments.content );
		var end     = 0;
		var excerpt = "";

		if ( match lte 250 ) {
			match = 1;
		}
		end = match + len( arguments.term ) + 500;

		if ( len( arguments.content ) gt 500 ) {
			if ( match gt 1 ) {
				excerpt = "..." & mid( arguments.content, match - 250, end - match );
			} else {
				excerpt = left( arguments.content, end );
			}
			if ( len( arguments.content ) gt end ) {
				excerpt = excerpt & "...";
			}
		} else {
			excerpt = arguments.content;
		}

		try {
			excerpt = reReplaceNoCase(
				excerpt,
				"(#arguments.term#)",
				"<span class='highlight'>\1</span>",
				"all"
			);
		} catch ( Any e ) {
		}

		// remove images
		// excerpt = reReplaceNoCase(excerpt, '<img\s[^//>].*//?>',"[image]","all" );
		// remove links
		// excerpt = reReplaceNoCase(excerpt, '<a\b[^>]*>(.*?)</a>',"[link]","all" );

		return excerpt;
	}

</cfscript>
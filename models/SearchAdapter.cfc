/**
 * Elasticsearch ContentBox Search Proider
 * Copyright since 2012 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 *
 * @see contentbox.models.search.ISearchAdapter
 */
component accessors="true" singleton {

	// DI
	property name="wirebox"          inject="wirebox";
	property name="cb"               inject="cbHelper@contentbox";
	property name="searchClient"     inject="Client@cbelasticsearch";
	property name="moduleSettings"   inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="requestService"   inject="coldbox:RequestService";
	property name="renderer"         inject="Renderer@coldbox";

	variables.dateFormatter = createObject( "java", "java.text.SimpleDateFormat" ).init(
		"yyyy-MM-dd'T'HH:mm:ssXXX"
	);

	/**
	 * Constructor
	 */
	SearchAdapter function init(){
		return this;
	}

	/**
	 * Provider function for a new search builder
	 */
	function newSearchBuilder() provider="SearchBuilder@cbelasticsearch"{}

	/**
	 * Search content and return an standardized ContentBox Results object.
	 *
	 * @searchTerm The search term to search on
	 * @max        The max results to return if paging
	 * @offset     The offset to use in the search results if paging
	 * @siteID     The site to filter on if passed
	 *
	 * @return contentbox.models.search.SearchResults Object
	 */
	SearchResults function search(
		required string searchTerm,
		numeric max    = 0,
		numeric offset = 0,
		string siteID  = ""
	){
		// get new search results object
		var searchResults = variables.wirebox.getInstance( "SearchResults@contentbox" );
		var sTime         = getTickCount();
		var contentTypes  = moduleSettings.contentTypes;
		if ( moduleSettings.ingestMedia ) {
			contentTypes.append( "Media" )
		}
		var builder = newSearchBuilder()
			.setIndex( variables.moduleSettings.searchIndex )
			.setMaxRows( arguments.max )
			.setStartRow( arguments.offset )
			.filterTerm( "isDeleted", false )
			.filterTerm( "isPublished", true )
			.filterTerm( "showInSearch", true )
			.filterTerms( "contentType", contentTypes )
			.dateMatch( name = "expireDate", start = dateFormatter.format( now() ) )
			.setSource( { "includes" : [], "excludes" : [ "blob" ] } );

		if ( len( arguments.siteID ) ) {
			builder.filterTerm( "siteID", arguments.siteID )
		}

		if ( len( searchTerm ) ) {
			var matchFields = [
				"title^10",
				"HTMLTitle^6",
				"HTMLDescription^5",
				"excerpt^4",
				"creator^3",
				"content^2"
			];
			builder.multiMatch(
				matchFields,
				trim( arguments.searchTerm ),
				30.00
			);
			builder.sort( "_score DESC" );
		} else {
			builder.sort( "publishedDate DESC" );
		}

		var results = builder.execute();

		try {
			// populate the search results
			searchResults.populate( {
				results    : results.getHits().map( function( doc ){ return doc.getMemento(); } ),
				total      : results.getHitCount(),
				searchTime : getTickCount() - sTime,
				searchTerm : arguments.searchTerm,
				error      : false
			} );
		} catch ( Any e ) {
			searchResults.setError( true );
			searchResults.setErrorMessages( [ "Error executing content search: #e.detail# #e.message#" ] );
		}

		return searchResults;
	}

	/**
	 * If chosen to be implemented, it should refresh search indexes and collections
	 */
	SearchAdapter function refresh(){
	}

	/**
	 * Render the search results according to the adapter and returns HTML
	 *
	 * @searchResults The search results object
	 */
	any function renderSearch(
		required string searchTerm,
		numeric max    = 0,
		numeric offset = 0
	){
		var searchResults = search( argumentCollection = arguments );
		variables.requestService.getContext().setPrivateValue( "searchResults", searchResults );
		return renderSearchWithResults( searchResults );
	}

	/**
	 * Render the search results according the passed in search results object
	 *
	 * @searchResults The search results object
	 */
	any function renderSearchWithResults( required SearchResults searchResults ){
		resultViewArgs           = duplicate( variables.moduleSettings.resultsTemplate );
		resultViewArgs[ "args" ] = { "results" : arguments.searchResults };
		return renderer.renderView( argumentCollection = resultViewArgs );
	}

}

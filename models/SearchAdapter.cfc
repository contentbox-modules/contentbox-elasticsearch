/**
 * Elasticsearch ContentBox Search Proider
 * Copyright since 2012 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * @see contentbox.models.search.ISearchAdapter
 */
component accessors="true" singleton {

	// DI
	property name="wirebox" inject="wirebox";
	property name="cb" inject="cbHelper@contentbox";
	property name="searchClient" inject="Client@cbelasticsearch";
	property name="newSearchBuilder" inject="provider:SearchBuilder@cbelasticsearch";
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="renderer" inject="Renderer@coldbox";

	/**
	 * Constructor
	 */
	SearchAdapter function init(){
		return this;
	}

	/**
	 * Search content and return an standardized ContentBox Results object.
	 *
	 * @searchTerm The search term to search on
	 * @max The max results to return if paging
	 * @offset The offset to use in the search results if paging
	 * @siteID The site to filter on if passed
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
		var contentTypes = moduleSettings.contentTypes;
		if( moduleSettings.ingestMedia ){
			contentTypes.append( "Media" )
		}
		var builder = newSearchBuilder()
			.setMaxRows( arguments.max )
			.setStartRow( arguments.offset )
			.filterTerm( "isDeleted" : false )
			.filterTerm( "isPublished" : true )
			.filterTerm( "showInSearch" : true )
			.filterTerms( "contentType", contentTypes )
			.dateMatch( field="expireDate", start=now() )
			setSource({
                "includes" : [],
                "excludes" : [
                    "blob"
                ]
            });

		if( len( arguments.siteID  ) ){
			builder.filterTerm( "siteID", arguments.siteID )
		}

		if( len( searchTerm ) ){
			var matchText = [
                "title^8",
                "HTMLTitle^6",
                "HTMLDescription^5",
				"excerpt^4",
				"creator^2",
                "content"
            ];
			builder.multiMatch(
				matchFields,
				trim( arguments.searchTerm ),
				30.00
			);
			search.sort( "_score DESC" );
		} else {
            search.sort( "createdTime DESC" );
		}

		var results = build.execute();

		try {
			// populate the search results
			searchResults.populate( {
				results    : results.getHits(),
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
	 *
	 * @return contentbox.models.search.ISearchAdapter
	 */
	SearchProvider function refresh(){}

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
		return renderSearchWithResults( searchResults );
	}

}

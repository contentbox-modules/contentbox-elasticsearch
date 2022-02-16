component {

	property name="contentService" inject="ContentService@contentbox";
	property name="newDocument"    inject="provider:Document@cbelasticsearch";
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="esClient"       inject="Client@cbelasticsearch";
	property name="wirebox"        inject="wirebox";

	variables.dateFormatter = createObject( "java", "java.text.SimpleDateFormat" ).init(
		"yyyy-MM-dd'T'HH:mm:ssXXX"
	);

	/**
	 * Ensures the search index on DI complete
	 */
	function onDIComplete(){
		wirebox
			.getInstance( "SearchIndex@escontentbox" )
			.ensureSearchIndex()
			.ensurePipelines();
	}

	/**
	 * Serializes an individual content entity
	 *
	 * @entity
	 * @refresh   whether to wait for the document to be saved and re-indexed
	 */
	struct function serialize( required BaseContent entity, refresh = false ){
		if ( !arguments.entity.isLoaded() ) {
			throw(
				type    = "ESContentBox.unloadedEntityException",
				message = "The entity provided was not loaded and contains no data.  Could not continue"
			);
		}

		var entityIncludes = [
			"contentID:_id",
			"contentID",
			"contentType",
			"createdDate",
			"slug",
			"creator.fullName:creator",
			"categoriesArray:categories",
			"expireDate",
			"featuredImage",
			"featuredImageURL",
			"title",
			"HTMLDescription",
			"HTMLKeywords",
			"HTMLTitle",
			"isPublished",
			"isDeleted",
			"modifiedDate",
			"publishedDate",
			"showInSearch",
			"site.siteID:siteID",
			"parentID",
			"excerpt",
			"renderedContent:content"
		];

		var memento = arguments.entity.getMemento(
			includes       = entityIncludes,
			ignoreDefaults = true,
			iso8601Format  = true
		);

		if ( !len( memento.expireDate ) ) {
			// make sure we have an expire date for comparisons
			memento.expireDate = dateFormatter.format( dateAdd( "y", 100, now() ) );
		}
		if ( isStruct( memento.creator ) ) {
			memento.creator = memento.creator.creator;
		}
		if( memento.keyExists( "site" ) && isStruct( memento.site ) ){
			memento[ "siteID" ] = memento.site.siteID;
			structDelete( memento, "site" );
		}

		var doc = variables.newDocument
			.setIndex( moduleSettings.searchIndex )
			.setPipeline( variables.moduleSettings.pipeline )
			.populate( memento )
			.save( arguments.refresh );

		return doc.getMemento();
	}

	/**
	 * Bulk serializes all content in the system
	 *
	 * @criteria An optional restrictive criteria query to pass in
	 * @refresh   whether to wait for the bulk operation to complete re-indexing before returning a result
	 */
	function serializeAll( criteria, refresh = false ){
		var projectionIncludes = [
			"contentID",
			"contentType",
			"createdDate",
			"slug",
			"creator.firstName",
			"creator.lastName",
			"categories.category:category",
			"expireDate",
			"featuredImage",
			"featuredImageURL",
			"title",
			"HTMLDescription",
			"HTMLKeywords",
			"HTMLTitle",
			"isPublished",
			"isDeleted",
			"modifiedDate",
			"publishedDate",
			"showInSearch",
			"site.siteID:siteID",
			"parent.contentID:parentID",
			"excerpt",
			"activeContent.content:content"
		];

		if ( isNull( arguments.criteria ) ) {
			arguments.criteria = variables.contentService.newCriteria();
		}
		var q = arguments.criteria;
		var r = q.restrictions;

		var ops = q
			.createAlias( "parent", "parent", q.LEFT_JOIN )
			.createAlias( "creator", "creator" )
			.createAlias( "site", "site" )
			.createAlias( "categories", "categories", q.LEFT_JOIN )
			.createAlias(
				"contentVersions",
				"activeContent",
				q.INNER_JOIN,
				r.isEq( "activeContent.isActive", javacast( "boolean", true ) )
			)
			.isIn( "this.contentType", variables.moduleSettings.contentTypes )
			.withProjections( property = projectionIncludes.toList() )
			.asStruct()
			.list( asQuery = false )
			.reduce( function( acc, item ){
				var exists = acc.find( function( entry ){
					return entry[ "contentID" ] == item[ "contentID" ];
				} );
				if ( exists ) {
					var entry = acc[ exists ];
				} else {
					var entry = item;
					entry
						.keyArray()
						.each( function( key ){
							if ( !isNull( entry[ key ] ) && isDate( entry[ key ] ) && !isNumeric( entry[ key ] ) ) {
								entry[ key ] = dateFormatter.format( entry[ key ] );
							}
						} );
					entry[ "categories" ] = [];
					entry[ "creator" ]    = [
						entry[ "creator.firstName" ],
						entry[ "creator.lastName" ]
					].toList( " " );
					structDelete( entry, "creator.firstName" );
					structDelete( entry, "creator.lastName" );
					acc.append( entry );
				}
				if ( !isNull( entry[ "category" ] ) && len( entry[ "category" ] ) ) {
					entry[ "categories" ].append( entry[ "category" ] );
				}
				if ( isNull( entry[ "expireDate" ] ) ) {
					entry[ "expireDate" ] = dateFormatter.format( dateAdd( "y", 100, now() ) );
				}
				structDelete( entry, "category" );
				return acc;
			}, [] )
			.map( function( item ){
				return {
					"operation" : {
						"update" : {
							"_index" : moduleSettings.searchIndex,
							"_id"    : item[ "contentID" ]
						}
					},
					"source" : { "doc" : item, "doc_as_upsert" : true }
				};
			} );

		return variables.esClient.processBulkOperation(
			operations = ops,
			params     = {
				"pipeline" : variables.moduleSettings.pipeline,
				"refresh"  : arguments.refresh ? "wait_for" : false
			}
		);
	}

}

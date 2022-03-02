component {

	property name="contentService" inject="ContentService@contentbox";
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

	function newDocument() provider="Document@cbelasticsearch"{}

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

		// Add our prc.page value so that cbHelper can render content
		var event = application.cbcontroller.getRequestService().getContext();
		event.setPrivateValue( "page", arguments.entity );

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

		memento.keyArray().each( function( key ){
			// Ensure ISO8601 format for odd payload values
			if( right( key, 4 ) == 'Date' && structKeyExists( memento, key ) && !isNull( memento[ key ] ) && len( memento[ key ] ) && !findNoCase( 'T', memento[ key ] ) ){
				memento[ key ] = dateFormatter.format( lsParseDateTime( memento[ key ] ) )
			}
		} );

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

		var doc = newDocument()
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
	 * @batchMaximum The maximum number of items to serialize per batch operation
	 */
	function serializeAll( criteria, refresh = false, batchMaximum=100 ){
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
			arguments.criteria = getEligibleContentCriteria();
		}
		var q = arguments.criteria;
		var r = q.restrictions;

		var ops = [];

		var total = q.count();

		// Serialize in batches of 100
		for( var i = 0; i <= total; i+=50 ){
			var segment = q
				.withProjections( property = projectionIncludes.toList() )
				.asStruct()
				.list( asQuery = false, max = 20, offset = i )
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
								if ( right( key, 4 ) == "Date" && structKeyExists( entry, key ) && !isNull( entry[ key ] ) && isDate( entry[ key ] ) && !isNumeric( entry[ key ] ) ) {
									entry[ key ] = dateFormatter.format( entry[ key ] );
								}
							} );
						entry[ "categories" ] = [];
						var creator = [
							entry[ "creator.firstName" ],
							entry[ "creator.lastName" ]
						];
						entry[ "creator" ]    = creator.toList( " " );
						structDelete( entry, "creator.firstName" );
						structDelete( entry, "creator.lastName" );
						acc.append( entry );
					}
					// ACF protection + full null support
					if ( structKeyExists( entry, "category" ) && !isNull( entry[ "category" ] ) && len( entry[ "category" ] ) ) {
						entry[ "categories" ].append( entry[ "category" ] );
					}
					if( !structKeyExists( entry, "expireDate" ) || isNull( entry[ "expireDate" ] ) ) {
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

			arrayAppend(
				ops,
				variables.esClient.processBulkOperation(
					operations = segment,
					params     = {
						"pipeline" : variables.moduleSettings.pipeline,
						"refresh"  : arguments.refresh ? "wait_for" : false
					}
				),
				true
			);
		}

		return ops;

	}

	function getEligibleContentCriteria( boolean withJoins = true ){
		var q = variables.contentService.newCriteria();
		var r = q.restrictions;
		if( arguments.withJoins ){
			q.createAlias( "parent", "parent", q.LEFT_JOIN )
				.createAlias( "creator", "creator" )
				.createAlias( "site", "site" )
				.createAlias( "categories", "categories", q.LEFT_JOIN );
		}
		var contentSub = q.createSubcriteria( "cbContentVersion", "activeContent" )
								.createAlias( "relatedContent", "relatedContent" )
								.isEq( "activeContent.isActive", javacast( "boolean", true ) )
								.Conjunction([
									r.like( "activeContent.content", "%widget%" ),
									r.like( "activeContent.content", "%Relocate%" )
								])
								.withProjections( property="relatedContent.contentID" );

		return q.createAlias(
					"contentVersions",
					"activeContent",
					q.INNER_JOIN,
					r.isEq( "activeContent.isActive", javacast( "boolean", true ) )
				)
				.isEq( "this.showInSearch", javacast( "boolean", true ) )
				.isEq( "this.isPublished", javacast( "boolean", true ) )
				.isEq( "this.isDeleted", javacast( "boolean", false ) )
				.isIn( "this.contentType", variables.moduleSettings.contentTypes )
				// exclude relocation widget content
				.add( contentSub.propertyNotIn( "contentID" ) )
	}

}

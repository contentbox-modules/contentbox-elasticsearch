component{
	property name="contentService" inject="ContentService@contentbox";
	property name="newDocument" provider="Document@cbelasticsearch";
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="esClient" inject="Client@cbelasticsearch";

	variables.entityIncludes = [
		"contentID:_id",
		"contentID",
		"contentType",
		"createdDate",
		"creator.fullName:creator",
		"categoriesArray:categories",
		"expireDate",
		"featuredImageURL",
		"HTMLDescription",
		"HTMLKeywords",
		"HTMLTitle",
		"isPublished",
		"isDeleted",
		"modifiedDate",
		"publishedDate",
		"showInSearch",
		"site.siteID:siteID",
		"parent.parentID:parentID",
		"excerpt",
		"renderedContent:content"
	];

	function serialize( required BaseContent entity ){
		newDocument()
			.setIndex( moduleSettings.searchIndex )
			.setPipeline( variables.moduleSettings.pipline )
			.populate( arguments.entity.getMemento( includes=variables.entityIncludes, ignoreDefaults=true ) ).save();
	}

	function bulkSerializeAll( criteria ){

		var projectionIncludes = [
			"contentID:_id",
			"contentID",
			"contentType",
			"createdDate",
			"creator.firstName",
			"creator.lastName",
			"categories.name:category",
			"expireDate",
			"featuredImageURL",
			"HTMLDescription",
			"HTMLKeywords",
			"HTMLTitle",
			"isPublished",
			"isDeleted",
			"modifiedDate",
			"publishedDate",
			"showInSearch",
			"site.siteID:siteID",
			"parent.parentID:parentID",
			"excerpt",
			"activeContent.content:content"
		];

		if( !arguments.criteria ){
			arguments.criteria = variables.contentService.newCriteria();
		}
		var q = arguments.criteria;
		var r = q.restrictions;

		var ops = q.isIn( "contentType", variables.moduleSettings.contentTypes )
								.createAlias( "parent", "parent", q.LEFT_JOIN )
								.createAlias( "creator", "creator" )
								.createAlias( "site", "site" )
								.createAlias( "categories", "categories", q.LEFT_JOIN )
								.createAlias( "contentVersions", "activeContent", q.INNER_JOIN, r.isEq( "isActive", javacast( "boolean", true ) ) )
								.withProjections( properties = projectionIncludes )
								.asStruct()
								.list( asQuery=true )
								.reduce( function( acc, item ){
									var exists = acc.find( function( entry){ return entry[ "contentID" ] == item[ "contentID" ]; } );
									if( exists ){
										var entry = acc[ exists ];
									} else {
										var entry = item;
										entry[ "categories" ] = [];
										entry[ "creator" ] = [ entry[ "creatore.firstName" ], entry[ "creator.lastName" ].toList( " " );
										structDelete( entry[ "creator.firstName" ] );
										structDelete( entry[ "creator.lastName" ] );
										acc.append( entry );
									}
									if( len( entry[ "category" ] ) ){
										entry[ "categories" ].append( entry[ "category" ] );
									}
									structDelete( entry, "category" );
									return acc;
								},[] ).map(
									function( item ){
										return {
											"operation" : {
												"update" :  {
													"_index" : moduleSettings.searchIndex,
													"_id" : item[ "_id" ]
												}
											},
											"source" : {
												"doc" : item,
												"doc_as_upsert" : true
											}
										}
									}
								);

		variables.esClient.processBulkOperation( operations=ops, params={ "pipeline" : variables.moduleSettings.pipline } )

	}

}
/**
* My BDD Test
*/
component extends="tests.resources.BaseTest"{

/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
		variables.model = prepareMock( new escontentbox.models.serializers.ContentSerializer() );
		getWirebox().autowire( variables.model );
		if( !variables.searchClient.indexExists( variables.moduleSettings.searchIndex ) ){
			getWirebox().getInstance( "SearchIndex@escontentbox" ).ensureSearchIndex().ensurePipelines();
		}
	}

	// executes after all suites+specs in the run() method
	function afterAll(){

	}

/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "Content Serializer Tests", function(){
			beforeEach( function(){
				var searchQuery = newSearchBuilder().setIndex( variables.moduleSettings.searchIndex ).setQuery( { "match_all" : {} } );
				variables.searchClient.deleteByQuery( searchQuery );
			});

			it( "Tests the ability to serialize a single content item", function(){
				var supportPage = getWirebox().getInstance( "PageService@contentbox" ).findByTitle( "support" );
				expect( supportPage ).toBeInstanceOf( "Page" );
				expect( supportPage.isLoaded() ).toBeTrue();
				variables.model.serialize( supportPage, true );

				var contentDoc = variables.searchClient.get( supportPage.getId(), variables.moduleSettings.searchIndex );
				expect( contentDoc ).toBeInstanceOf( "cbelasticsearch.models.Document" );

				var docMemento = contentDoc.getMemento();

				debug( docMemento );

				expect( docMemento )
					.toHaveKey( "contentID" )
					.toHaveKey( "title" )
					.toHaveKey( "isPublished" )
					.toHaveKey( "publishedDate" )
					.toHaveKey( "createdDate" )
					.toHaveKey( "featuredImage" )
					.toHaveKey( "featuredImageURL" )
					.toHaveKey( "excerpt" )
					.toHaveKey( "content" )
					.toHaveKey( "meta" );

			});

			it( "Tests the ability to bulk serialize all content items", function(){
				variables.model.serializeAll( refresh=true );
				var q = getWirebox()
							.getInstance( "ContentService@contentbox" )
							.newCriteria();

				var pageCount = q.createAlias( "parent", "parent", q.LEFT_JOIN )
									.createAlias( "creator", "creator" )
									.createAlias( "site", "site" )
									.createAlias(
										"contentVersions",
										"activeContent",
										q.INNER_JOIN,
										q.restrictions.isEq( "activeContent.isActive", javacast( "boolean", true ) )
									)
									.isIn( "contentType", variables.moduleSettings.contentTypes )
									.count();

				var docCount = newSearchBuilder().new( index=variables.moduleSettings.searchIndex ).setQuery( {"match_all" : {} } ).count();

				expect( docCount ).toBe( pageCount );
			} );

		});
	}

}


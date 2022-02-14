/**
 * My BDD Test
 */
component extends="tests.resources.BaseTest" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
		variables.model = prepareMock( new escontentbox.models.serializers.MediaSerializer() );
		getWirebox().autowire( variables.model );
		if ( !variables.searchClient.indexExists( variables.moduleSettings.searchIndex ) ) {
			getWirebox()
				.getInstance( "SearchIndex@escontentbox" )
				.ensureSearchIndex()
				.ensurePipelines();
		}
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
	}

	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		describe( "Static Methods Tests", function(){
			it( "Tests getSiteIdFromPath", function(){
				var defaultSite = getWirebox().getInstance( "SiteService@contentbox" ).findBySlug( "default" );
				expect( defaultSite.isLoaded() ).toBeTrue();
				var siteIdFromPath = variables.model.getSiteIdFromPath( '/contentbox-custom/_content/sites/default/test1234/test.pdf' );
				expect( siteIdFromPath ).toBeString().toBe( defaultSite.getSiteId() );
			} );
		} );
		// all your suites go here.
		describe( "Media Serializer Tests", function(){
			beforeEach( function(){
				var searchQuery = newSearchBuilder()
					.setIndex( variables.moduleSettings.searchIndex )
					.setQuery( { "match_all" : {} } );
				variables.searchClient.deleteByQuery( searchQuery );
			} );

			it( "Tests the ability to serialize a single content item", function(){
				var defaultSite = getWirebox().getInstance( "SiteService@contentbox" ).findBySlug( "default" );
				expect( defaultSite.isLoaded() ).toBeTrue();
				var mediaFile = '/contentbox-custom/_content/sites/default/SerializerTest.pdf';

				var result = variables.model.serialize( mediaPath=mediaFile, refresh=true );

				expect( result ).toBeStruct().toHaveKey( "contentID" ).toHaveKey( "path" );

				var contentDoc = variables.searchClient.get(
					result.contentID,
					variables.moduleSettings.searchIndex
				);
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

				expect( !!len( docMemento.content ) ).toBeTrue();
				expect( !!findNoCase( "United Way", docMemento.content ) ).toBeTrue();
				expect( docMemento.siteID ).toBe( defaultSite.getSiteID() );
			} );

			it( "Tests the ability to bulk serialize all content items", function(){
				var contentDirectory = '/contentbox-custom/_content/sites/default';
				var serializationResult = variables.model.serializeAll( directory=contentDirectory, refresh = true );

				debug( serializationResult );

				var searchCount = newSearchBuilder()
					.new( index = variables.moduleSettings.searchIndex )
					.setQuery( { "match_all" : {} } )
					.count();

				expect( serializationResult.len() ).toBe( searchCount );
			} );
		} );
	}

}


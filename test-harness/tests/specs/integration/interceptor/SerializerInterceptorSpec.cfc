/**
 * My BDD Test
 */
component extends="tests.resources.BaseTest" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
		variables.model = prepareMock( new escontentbox.interceptors.Serializer() );
		getWirebox().autowire( variables.model );
		variables.model.$(
			method="getInstance",
			callback=function(
				name,
				struct initArguments = {},
				dsl,
				targetObject = "",
				injector
			){
				return getWirebox().getInstance( argumentCollection = arguments );
			}
		);
		makePublic( variables.model, "postPersist", "postPersist" );
		variables.testFile = expandPath( '/contentbox-custom/_content/sites/default/SerializerTest.pdf' );
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
	}

	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "File Interception Specs", function(){
			beforeEach( function(){
				getWirebox().getInstance( "Client@cbelasticsearch" ).deleteByQuery(
					getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.term( "contentType", "File" ),
					true
				)
			} );
			it( "Tests fb_postFileUpload", function(){
				var event = getMockRequestContext();
				var interceptData = {
					"path" : variables.testFile
				}
				variables.model.fb_postFileUpload( event, interceptData );

				sleep( 100 );

				var serializedDoc = getInstance( "Client@cbelasticsearch" ).get( hash( interceptData.path ), variables.moduleSettings.searchIndex );
				expect( isNull( serializedDoc ) ).toBeFalse();
				expect( serializedDoc.getMemento() ).toBeStruct().toHaveKey( "content" ).toHaveKey( "featuredImage" );
				expect( serializedDoc.getMemento().featuredImage ).toBe( interceptData.path );

			});
			it( "Tests fb_preFileRemoval", function(){
				getInstance( "MediaSerializer@escontentbox" ).serialize( variables.testFile, {}, true );
				expect( getInstance( "Client@cbelasticsearch" ).get( hash( variables.testFile ), variables.moduleSettings.searchIndex ) )
					.toBeInstanceOf( "cbelasticsearch.models.Document" );

				var event = getMockRequestContext();
				var interceptData = {
					"path" : variables.testFile
				}
				variables.model.fb_preFileRemoval( event, interceptData );

				expect(
					getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.term( "contentID", hash( variables.testFile ) )
						.count()
				).toBe( 1 );

			} );
		} );

		describe( "ORM Interception Specs", function(){
			beforeEach( function(){
				getWirebox().getInstance( "Client@cbelasticsearch" ).deleteByQuery(
					getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.filterTerms( "contentType", [ "Page", "Entry" ] ),
					true
				);
			} );
			it( "Tests postPersist method", function(){
				var testEntity = getWirebox().getInstance( "PageService@contentbox" ).findBySlug( "products" );
				expect( testEntity.isLoaded() ).toBeTrue();
				expect(
					getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.term( "contentID", testEntity.getContentID() )
						.count()
				).toBe( 0 );
				var event = getMockRequestContext();
				var interceptData = { "entity" : testEntity };

				variables.model.postPersist( event, interceptData );
				expect(
					getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.term( "contentID", testEntity.getContentID() )
						.count()
				).toBe( 0 );
			} );
			it( "Tests ORMpreDelete method", function(){
				var testEntity = getWirebox().getInstance( "PageService@contentbox" ).findBySlug( "products" );
				expect( testEntity.isLoaded() ).toBeTrue();
				expect( testEntity.getContentType() ).toBe( "Page" );
				getInstance( "ContentSerializer@escontentbox" ).serialize( testEntity, true );
				expect(
					getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.term( "contentID", testEntity.getContentID() )
						.count()
				).toBe( 1 );

				var event = getMockRequestContext();
				var interceptData = { "entity" : testEntity };
				variables.model.ORMPreDelete( event, interceptData );
				sleep( 1000 );
				expect(
					getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.term( "contentID", testEntity.getContentID() )
						.count()
				).toBe( 0 );
			} );
		});
	}

}


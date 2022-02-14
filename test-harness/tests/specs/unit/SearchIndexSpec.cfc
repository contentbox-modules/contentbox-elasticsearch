/**
 * My BDD Test
 */
component extends="tests.resources.BaseTest" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
		variables.model = prepareMock( new escontentbox.models.indexing.SearchIndex() );
		getWirebox().autowire( variables.model );
	}


	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "Search Index Management Tests", function(){
			beforeEach( function(){
				getInstance( "Client@cbelasticsearch" ).deleteIndex( variables.moduleSettings.searchIndex & "*" );
				getController().getCachebox().getCache( "default" ).clear( "contentBoxSearchIndexAssured" );
				sleep( 100 );
			} );
			it( "Tests ensureSearchIndex method", function(){
				expect( getInstance( "Client@cbelasticsearch" ).indexExists( variables.moduleSettings.searchIndex ) ).toBeFalse();
				variables.model.ensureSearchIndex();
				expect( getInstance( "Client@cbelasticsearch" ).indexExists( variables.moduleSettings.searchIndex ) ).toBeTrue();
			} );

			it( "Tests ensurePipelines method", function(){
				expect( getInstance( "Client@cbelasticsearch" ).indexExists( variables.moduleSettings.searchIndex ) ).toBeFalse();
				variables.model.ensureSearchIndex();
				variables.model.ensurePipelines();
				var pipeline = getInstance( "Client@cbelasticsearch" ).getPipeline( variables.moduleSettings.pipeline );
				expect( pipeline ).toBeStruct().toHaveKey( "processors" ).toHaveKey( "description" ).toHaveKey( "version" );
			} )
		} );
	}

}


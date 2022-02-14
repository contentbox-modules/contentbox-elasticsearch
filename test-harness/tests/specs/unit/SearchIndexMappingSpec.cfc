/**
 * My BDD Test
 */
component extends="tests.resources.BaseTest" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
		variables.model = new escontentbox.models.mapping.SearchIndexMapping();
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
	}

	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "Mapping Object Tests", function(){
			it( "Tests the ability to retrieve the config", function(){
				expect( variables.model.getConfig() ).toBeStruct().toHaveKey( "mappings" );
			} );
		} );
	}

}


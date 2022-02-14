/**
 * My BDD Test
 */
component extends="tests.resources.BaseTest" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
		variables.model = prepareMock( new escontentbox.models.SearchAdapter() );
		getWirebox().autowire( variables.model );
		getInstance( "SearchIndex@escontentbox" ).ensureSearchIndex().ensurePipelines();
		getInstance( "ContentSerializer@escontentbox" ).serializeAll( refresh=true );
	}


	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "Search Index Management Tests", function(){
			it( "Tests search method", function(){
				var searchResults = variables.model.search( "ContentBox" );
				expect( searchResults ).toBeInstanceOf( "contentbox.models.search.SearchResults" );
				expect( searchResults.getResults() ).toBeArray();
				expect( searchResults.getTotal() ).toBe( 2 );
			} );

			it( "Tests renderSearch method", function(){
				var context = getRequestContext();
				var rc = context.getCollection();
				rc.q = "ContentBox";
				var prc = context.getPrivateCollection();
				prc.oPaging          = getInstance( "paging@contentbox" );
				prc.cbSettings       = getInstance( "SettingService@contentbox" ).getAllSettings();
				prc.pagingBoundaries = prc.oPaging.getBoundaries(
					pagingMaxRows: 10
				);
				prc.pagingLink = "/#urlEncodedFormat( rc.q )#/@page@";

				var searchHTML = variables.model.renderSearch( rc.q, 10 );
				expect( !!findNoCase( "ContentBox Modular CMS", searchHTML ) ).toBeTrue();
			} );
		} );
	}

}


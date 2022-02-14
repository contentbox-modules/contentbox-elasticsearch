/**
* This is the ForgeBox Base Integration Test CFC
* Place any helpers or traits for all integration tests here.
*/
component extends="coldbox.system.testing.BaseTestCase" appMapping="/root" autowire=false {
	property name="searchClient";
	property name="moduleSettings";

	// Do not unload per test bundle to improve performance.
	this.loadColdbox = true;
	this.unloadColdBox = false;

	function init(){
		variables.autowire = false;
		return this;
	}

/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
        super.beforeAll();
		var contentBoxModuleService = getWirebox().getInstance( "ModuleService@contentbox" );
		if( isNull( contentBoxModuleService.findByForgeboxSlug( "contentbox-elasticsearch" ) ) ){
			contentBoxModuleService.activateModule( "contentbox-elasticsearch" );
		}
		variables.searchClient = getWirebox().getInstance( "Client@cbelasticsearch" );
		variables.moduleSettings = getWirebox().getInstance( "coldbox:moduleSettings:contentbox-elasticsearch" );
        getWireBox().autowire( this );
	}

	function newSearchBuilder(){
		return getWirebox().getInstance( "SearchBuilder@cbelasticsearch" );
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
		super.afterAll();
	}

	function reset(){
		structDelete( application, "wirebox" );
		structDelete( application, "cbController" );
	}

}
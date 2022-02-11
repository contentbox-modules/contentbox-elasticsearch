component {

	// Module Properties
	this.title 				= "contentbox-elasticsearch";
	this.author 			= "Jon Clausen <jclausen@ortussolutions.com>";
	this.webURL 			= "https://ortussolutions.com";
	this.description 		= "Contentbox Elasticsearch Provider Module";
	this.version			= "1.0.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= false;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = false;
	// Module Entry Point
	this.entryPoint			= "contentbox-elasticsearch";
	// Inherit Entry Point
	this.inheritEntryPoint 	= false;
	// Model Namespace
	this.modelNamespace		= "escontentbox";
	// CF Mapping
	this.cfmapping			= "escontentbox";
	// Auto-map models
	this.autoMapModels		= true;
	// Module Dependencies
	this.dependencies 		= [ "cbelasticsearch" ];

	/**
	 * Configure the module
	 */
	function configure(){

		// module settings - stored in modules.name.settings
		settings = {
			"version" : this.version,
			"searchIndex" : "contentbox-content",
			"pipeline" : "contentbox_content",
			"contentTypes" : [ "Page", "Entry" ],
			// Whether to ingest media items
			"ingestMedia" : true,
			// CF directoryList exension filter
			"ingestExtensionFilter" : "*.pdf|*.doc|*.docx",
			// The directory for which to search for ingestable media
			"ingestBaseDirectory" : "/contentbox-custom/_content",
			"resultsTemplate" : {
				"module" : "contentbox-elasticsearch",
				"view" : "searchResults"
			}
		};

		// Custom Declared Interceptors
		interceptors = [
			{ class="escontentbox.interceptors.Content" }
		];

		// Binder Mappings
		// binder.map("Alias").to("#moduleMapping#.models.MyService");

	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
		try{
			controller.getWirebox().getInstance( "SearchIndex@escontentbox" ).ensureSearchIndex().ensurePipelines();
		} catch( any e ){
			controller.getLogbox().getRootLogger().error( "An attempt to create the elasticsearch index #settings.searchIndex# was made but an error occurred. The exception was #e.message#:#e.detail#" );
		}
	}

	/**
	 * Fired when the module is activated by ContentBox
	 */
	function onActivate(){

		// Add Admin Menu section
		var menuService = controller.getWireBox().getInstance( "AdminMenuService@contentbox" );
		// Add Menu Contribution
		menuService.addSubMenu(
			topMenu = menuService.MODULES,
			name    = "Elasticsearch",
			label   = "Elasticsearch",
			href    = "#menuService.buildModuleLink( "contentbox-elasticsearch", "Main" )#"
		);
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){}

	/**
	 * Fired when the module is deactivated by ContentBox
	 */
	function onDeactivate(){
		try{
			if( controller.getWirebox().getInstance( "Client@cbelasticsearch" ).indexExists( settings.searchIndex ) ){
				controller.getWirebox().getInstance( "Client@cbelasticsearch" ).deleteIndex( settings.searchIndex );
			}
		} catch( any e ){
			controller.getLogbox().getRootLogger().error( "An attempt to remove the elasticsearch index #settings.searchIndex# was made but an error occurred. The exception was #e.message#:#e.detail#" );
		}
		// Let's remove ourselves to the main menu in the Modules section
		var menuService = controller.getWireBox().getInstance( "AdminMenuService@contentbox" );
		// Remove Menu Contribution
		menuService.removeSubMenu( topMenu = menuService.MODULES, name = "Elasticsearch" );
	}
}
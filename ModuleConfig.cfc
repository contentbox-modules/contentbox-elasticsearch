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
			// The search index alias where the this ContentBox's data will be stored
			"searchIndex" : "contentbox-content",
			// The name of the pipeline used to handle the ingest of documents and media ( if enabled )
			"pipeline" : "contentbox_content",
			// The content types to serialize for search
			"contentTypes" : [ "Page", "Entry" ],
			// Whether to ingest media items
			"ingestMedia" : false,
			// CF directoryList exension filter
			"ingestExtensionFilter" : "*.pdf|*.doc|*.docx",
			// The directory for which to search for ingestable media
			"ingestBaseDirectory" : "/contentbox-custom/_content",
			// The template to use for displaying the search results
			"resultsTemplate" : {
				"module" : "contentbox-elasticsearch",
				"view" : "search/results",
				"isThemeView" : false
			}
		};

		// Custom Declared Interceptors
		interceptors = [
			{ class="escontentbox.interceptors.Serializer" }
		];

		variables.settingService = controller.getWireBox().getInstance( "SettingService@contentbox" );

		var dbSetting = settingService.findWhere( criteria = { name : "escontentbox", isCore : true } );

		if( !isNull( dbSetting ) && isJSON( dbSetting.getValue() ) ){
			structAppend( settings, deserializeJSON( dbSetting.getValue() ), true );
		}

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

		// Ensure our SES value is true for the build link call ( https://ortussolutions.atlassian.net/browse/COLDBOX-1096 )
		controller.getRequestService().getContext().setSESEnabled( true );

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
	 * Fired when the module is activated by ContentBox
	 */
	function onActivate(){

		var settingExists = variables.settingService.newCriteria()
														.isEq( "name", "escontentbox" )
														.isEq( "isCore", javacast( "boolean", true ) )
														.count();

		if( !settingExists ){
			var setting = variables.settingService.new( properties={
				"name" : "escontentbox",
				"isCore" : javacast( "boolean", true ),
				"value" : controller.getWireBox().getInstance( "Util@cbelasticsearch" ).toJSON( settings )
			} );
			variables.settingService.save( setting );
		}
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

		var dbSetting = settingService.findWhere( criteria = { name : "escontentbox" } );

		if ( !isNull( dbSetting ) ) {
			settingService.delete( dbSetting );
		}

		// Restore our original search adapter
		var adapterSetting = settingService.findWhere( criteria = { name : "cb_search_adapter", isCore : true } );
		adapterSetting.setValue( "DBSearch@contentbox" );
		settingService.save( adapterSetting );

	}
}
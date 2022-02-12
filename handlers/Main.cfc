component {

	function index( event, rc, prc ){
		event.setView( "main/index" );
	}

	function seed( event, rc, prc ){
		getInstance( "ContentSerializer@cbElasticsearch" ).bulkSerializeAll();
		event.setView( "main/indices" );
	}

	function configuration( event, rc, prc ){
		event.setView( "main/configuration" );
	}

	function indices( event, rc, prc ){
		event.setView( "main/indices" );
	}

	function metrics( event, rc, prc ){
		event.setView( "main/metrics" );
	}

}

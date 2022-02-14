component {

	property name="moduleSettings"    inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="contentSerializer" inject="ContentSerializer@escontentbox";
	property name="cachebox"          inject="cachebox";
	property name="settingService"    inject="settingService@contentbox";

	/**
	 * ContentBox Post File Upload Interception Event
	 *
	 * @event
	 * @interceptData
	 */
	function fb_postFileUpload( event, interceptData ){
		var eligibleExtensions = listToArray( moduleSettings.ingestExtensionFilter, "|" )
									.map( function( filter ){
										return listLast( filter, "." )
									} );
		if (
			moduleSettings.ingestMedia &&
			interceptData.keyExists( "path" ) &&
			eligibleExtensions.contains( listLast( interceptData.path, "." ) )
		) {
			getInstance( "MediaSerializer@escontentbox" ).serialize( interceptData.path );
		}
	}

	/**
	 * ContentBox Pre File Delete Interception
	 *
	 * @event
	 * @interceptData
	 */
	function fb_preFileRemoval( event, interceptData ){
		if (
			moduleSettings.ingestMedia &&
			interceptData.keyExists( "path" )
		) {
			var searchBuilder = getInstance( "SearchBuilder@cbelasticsearch" )
									.new( variables.moduleSettings.searchIndex )
									.term( "contentID", hash( interceptData.path ) );
			getInstance( "Client@cbelasticsearch" ).deleteByQuery( searchBuilder );
		}
	}

	/**
	 * ORM Post-Insert Interception Event
	 *
	 * @event
	 * @interceptData
	 */
	function ORMPostInsert( event, interceptData ){
		return postPersist( argumentCollection = arguments );
	}

	/**
	 * ORM Post-Save Interception Event
	 *
	 * @event
	 * @interceptData
	 */
	function ORMPostSave( event, interceptData ){
		return postPersist( argumentCollection = arguments );
	}

	function ORMPreDelete( event, interceptData ){
		if (
			isInstanceOf( interceptData.entity, "BaseContent" )
			&& variables.moduleSettings.contentTypes.contains(
				interceptData.entity.getContentType()
			)
		) {
			getInstance( "Client@cbelasticsearch" ).deleteByQuery(
				getInstance( "SearchBuilder@cbElasticsearch" )
						.new( variables.moduleSettings.searchIndex )
						.term(
							"contentID",
							interceptData.entity.getContentID()
						),
				true
			);
		}
	}

	/**
	 * Handles the post-persistence of content items for serialization to elasticsearch
	 *
	 * @event
	 * @interceptData
	 */
	private function postPersist( event, interceptData ){
		if (
			isInstanceOf( interceptData.entity, "BaseContent" )
			&& variables.moduleSettings.contentTypes.contains(
				interceptData.entity.getContentType()
			)
		) {
			// ensure our cache is cleared for newly rendered content
			variables.cachebox
				.getCache( variables.settingService.getSetting( "cb_content_cacheName" ) )
				.clearQuiet( interceptData.entity.buildContentCacheKey() );
			variables.contentSerializer.serialize( interceptData.entity );
		}
	}

}

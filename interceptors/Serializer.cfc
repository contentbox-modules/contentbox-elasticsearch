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
		var eligibleExtensions = moduleSettings.ingestExtensionFilter
			.toArray( "|" )
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

	/**
	 * Handles the post-persistence of content items for serialization to elasticsearch
	 *
	 * @event
	 * @interceptData
	 */
	private function postPersist( event, interceptData ){
		if (
			isInstanceOf( interceptData.entity, "BaseContent" ) && variables.moduleSettings.contentTypes.contains(
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

component{
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="contentSerializer" inject="ContentSerializer@escontentbox";
	property name="cachebox" inject="cachebox";
	property name="settingService" inject="id:settingService@contentbox";


	function ORMPostInsert( event, interceptData ){
		return postPersist( argumentCollection=arguments );
	}

	function ORMPostSave( event, interceptData ){
		//ensure our cache is cleared for newly rendered content
		variables.cachebox
					.getCache( variables.settingService.getSetting( "cb_content_cacheName" ) )
					.clearQuiet( interceptData.entity.buildContentCacheKey() );

		return postPersist( argumentCollection=arguments );
	}

	private function postPersist( event, interceptData ){
		if( isInstanceOf( interceptData.entity, "BaseContent" ) && variables.moduleSettings.contentTypes.contains( interceptData.entity.getContentType() ) ){
			variables.contentSerializer.serialize( interceptData.entity );
		}
	}

}
component extends="coldbox.system.RestHandler" {
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="searchClient" inject="Client@cbelasticsearch";
	property name="esUtil" inject="Util@cbelasticsearch";
	property name="cb" inject="cbHelper@contentbox";

	this.allowedMethods = {
		"settings" : "PUT,GET",
		"serialize" : "POST,DELETE",
		"indices" : "GET",
		"adapter" : "PATCH"
	};

	function settings( event, rc, prc ){
		var settingService = getInstance( "SettingService@contentbox" );
		var settingsObj = settingService.findWhere( criteria = { "name" : "escontentbox", "isCore" : true } );
		if( event.getHTTPMethod() == "PUT" ){
			var updatedSettings = event.getHTTPContent( json=true )
			structAppend( updatedSettings, moduleSettings , false );
			settingsObj.setValue( esUtil.toJSON( updatedSettings ) );
			settingService.save( settingsObj );
		}

		prc.response.setData( deserializeJSON( settingsObj.getValue() ) );
	}

	function indices( event, rc, prc ){

		var indices = variables.searchClient.getIndices()
		.filter( function( key, value ){
			return left( key, 1 ) != ".";
		} );
        var aliasMap = variables.searchClient.getAliases();

        indices.keyArray()
            .each( function( indexName ){
            indices[ indexName ][ "aliases" ] = [];
            aliasMap.aliases.keyArray().each( function( aliasName ){
                if( aliasMap.aliases[ aliasName ] == indexName ){
                    indices[ indexName ][ "aliases" ].append( aliasName );
                }
            } );
			indices[ indexName ][ "isPrimary" ] = !! indices[ indexName ].aliases.contains( moduleSettings.searchIndex );
        } );

		prc.response.setData( indices );

	}

	function serialize( event, rc, prc ){
		if( event.getHTTPMethod() == "DELETE" ){
			var search = getInstance( "SearchBuilder@cbelasticsearch" )
				.new( variables.moduleSettings.searchIndex, moduleSettings.searchIndex )
				.filterTerm( "contentID", rc.contentID )
				.param( "refresh", true );
			prc.response.setData(
				searchClient.deleteByQuery( search, true )
			);
		} else {
			switch( rc.contentType ){
				case "File":{
					var serializer = getInstance( "MediaSerializer@escontentbox" );
					break;
				}
				default:{
					var serializer = getInstance( "ContentSerializer@escontentbox" );
				}
			}

			if( structKeyExists( rc, "contentID" ) ){
				var result = serializer.serialize(
					rc.contentType == "File" ? rc.contentID : getInstance( "ContentService@contentbox" ).getOrFail( rc.contentID ),
					rc.contentType == 'File' ? {} : true,
					rc.contentType == 'File' ? true : javacast( "null", 0 )
				);
			} else {
				var result = serializer.serializeAll( refresh=true );
			}
			prc.response.setData( result );
		}


	}

	function adapter( event, rc, prc ){
		var settingService = getInstance( "SettingService@contentbox" );
		var adapterSetting = settingService.findWhere( criteria = { name : "cb_search_adapter", isCore : true } );
		adapterSetting.setValue( "SearchAdapter@escontentbox" );
		settingService.save( adapterSetting );
		settingservice.flushSettingsCache();
		prc.response.setStatusCode( 205 );
	}



	function snapshot( event, rc, prc ){
		var contentTypes = variables.moduleSettings.contentTypes;
		var searchIndex = variables.moduleSettings.searchIndex;
		var q = getInstance( "ContentService@contentbox" ).newCriteria();
		var r = q.restrictions;
		var dbSearchCriteria = getInstance( "ContentService@contentbox" )
									.newCriteria()
									.isIn( "this.contentType", contentTypes )
									.isEq( "site", cb.site() )
									.createAlias(
										"contentVersions",
										"activeContent",
										q.INNER_JOIN,
										r.isEq( "activeContent.isActive", javacast( "boolean", true ))
									);
		var dbContentCount = dbSearchCriteria.count();
		var mediaSearchBuilder = getInstance( "SearchBuilder@cbelasticsearch" ).new( searchIndex ).term( "contentType", "File" ).term( "siteID", cb.site().getId() );
		var contentSearchBuilder = getInstance( "SearchBuilder@cbelasticsearch" ).new( searchIndex ).filterTerms( "contentType", contentTypes ).term( "siteID", cb.site().getId() );
		var esContentCount = contentSearchBuilder.count();
		var serializedContent = contentSearchBuilder.setSourceIncludes( [ "contentID", "contentType", "title", "slug" ] )
																.setMaxRows( dbContentCount )
																.execute()
																.getHits()
																.map( function( doc ){ return doc.getMemento(); } );

		var esMediaCount = variables.moduleSettings.ingestMedia ? mediaSearchBuilder.count() : 0;
		var serializedMedia = variables.moduleSettings.ingestMedia
									? mediaSearchBuilder.setSourceIncludes( [ "contentID", "contentType", "title", "featuredImage" ] )
											.setMaxRows( esMediaCount )
											.execute()
											.getHits()
											.map( function( doc ){ return doc.getMemento(); } )
									: [];
		var eligibleMedia = variables.moduleSettings.ingestMedia
								? getInstance( "MediaSerializer@escontentbox" ).getEligibleMedia()
								: [];
		var eligibleContent = dbSearchCriteria.withProjections( property="contentID,slug,this.contentType:contentType,title" ).asStruct().list( asQuery=false );

		prc.response.setData(
			{
				"ingestMedia" : variables.moduleSettings.ingestMedia,
				"dbContentCount" : dbContentCount,
				"esContentCount" : esContentCount,
				"eligibleDbContent" : eligibleContent,
				"serializedDbContent" : serializedContent,
				"eligibleMediaCount" : eligibleMedia.len(),
				"esMediaCount" : esMediaCount,
				"eligibleMedia" : eligibleMedia,
				"serializedMedia" : serializedMedia
			}
		);
	}
}
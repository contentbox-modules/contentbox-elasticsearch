component {
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="settingService" inject="settingService@contentbox";
	property name="siteService"    inject="SiteService@contentbox";
	property name="esClient"       inject="Client@cbelasticsearch";
	property name="wirebox"        inject="wirebox";

	variables.dateFormatter = createObject( "java", "java.text.SimpleDateFormat" ).init(
		"yyyy-MM-dd'T'HH:mm:ssXXX"
	);

	function onDIComplete(){
		variables.defaultSiteId = variables.siteService.getDefaultsiteID();
	}

	function newDocument() provider="Document@cbelasticsearch"{}

	/**
	 * Serializes an individual media item with a provided path
	 *
	 * @mediaPath
	 * @memento   an optional memento of fields to add to the serialized document
	 * @refresh   whether to wait for the document to be saved and re-indexed
	 */
	struct function serialize( required string mediaPath, struct memento = {}, refresh=false ){

		// We need to ensure our path is always expanded so that key names remain consistent
		var isExpandedPath = findNoCase( expandPath( settingService.getSetting( "cb_media_directoryRoot" ) ), arguments.mediaPath );

		if ( !fileExists( arguments.mediaPath ) || !isExpandedPath ) {
			var providedPath    = arguments.mediaPath;
			arguments.mediaPath = expandPath( arguments.mediaPath );

			if ( !fileExists( arguments.mediaPath ) ) {
				throw(
					type    = "ESContentBox.missingFileException",
					message = "The file provided for media serialization, #providedPath#, does not exist in either an absolute or expanded path. Serialization cannot continue",
					detail  = "#serializeJSON( e, false, false )#"
				);
			}
		}

		var mediaDirectory = expandPath( settingService.getSetting( "cb_media_directoryRoot" ) );
		var mediaURL       = replace(
			arguments.mediaPath,
			mediaDirectory,
			"/__media"
		);

		param memento.contentID = hash( arguments.mediaPath );
		param memento._id       = memento.contentID;

		if ( !memento.keyExists( "siteID" ) ) {
			memento[ "siteID" ] = getSiteIDFromPath( arguments.mediaPath );
		}

		structAppend(
			arguments.memento,
			{
				"title"            : listLast( arguments.mediaPath, "\/" ),
				"contentType"      : "File",
				"excerpt"          : "",
				"content"          : "",
				"featuredImage"    : arguments.mediaPath,
				"featuredImageURL" : mediaURL,
				"slug"             : mediaURL,
				"blob"             : toBase64( fileReadBinary( arguments.mediaPath ) ),
				"isPublished" : javacast( "boolean", true ),
				"isDeleted" : javacast( "boolean", false ),
				"showInSearch" : javacast( "boolean", true ),
				"expireDate" : dateFormatter.format( dateAdd( "y", 100, now() ) ),
				"createdDate" : dateFormatter.format( now() ),
				"publishedDate" : dateFormatter.format( now() )
			},
			true
		);

		newDocument()
			.setIndex( moduleSettings.searchIndex )
			.setPipeline( variables.moduleSettings.pipeline )
			.populate( arguments.memento )
			.save( refresh = arguments.refresh );

		return { "contentID" : memento.contentID, "path" : arguments.mediaPath };
	}

	/**
	 * Serializes all media in the
	 *
	 * @directory An optional directory to restrict serialization to
	 * @refresh   whether to wait for the document to be saved and re-indexed
	 */
	array function serializeAll( directory, refresh=false ){

		var eligibleMedia = getEligibleMedia( argumentCollection=arguments );

		// We have to ingest each media item in its own request or we could overload the ES server
		return eligibleMedia.map( function( path ){
			return this.serialize(
				path,
				{
					"_id"       : hash( arguments.path ),
					"contentID" : hash( arguments.path ),
					"siteID"    : getSiteIDFromPath( arguments.path )
				},
				refresh
			);
		} );
	}

	function getSiteIDFromPath( required string path ){
		var isExpandedPath = findNoCase( expandPath( '/' ), arguments.path );
		var mediaDirectory = isExpandedPath ? expandPath( settingService.getSetting( "cb_media_directoryRoot" ) ) : settingService.getSetting( "cb_media_directoryRoot" );
		var sitePath       = replace( path, mediaDirectory, "" );
		if( listLen( sitePath, "\/" )  > 1 ){
			siteSlug           = listGetAt( sitePath, 2, "\/" );
			var mediaSite      = variables.siteService
									.newCriteria()
									.isEq( "slug", siteSlug )
									.withProjections( property = "siteID" )
									.asStruct()
									.get();
		} else {
			var mediaSite = javacast( "null", 0 );
		}
		return !isNull( mediaSite ) && !structIsEmpty( mediaSite ) ? mediaSite[ "siteID" ] : variables.defaultSiteId;
	}

	function getEligibleMedia( directory ){
		var searchPath       = arguments.directory ?: expandPath( moduleSettings.ingestBaseDirectory );
		var searchExtensions = moduleSettings.ingestExtensionFilter;

		return directoryList(
			searchPath,
			true,
			"path",
			searchExtensions,
			"textnocase",
			"file"
		);
	}

}

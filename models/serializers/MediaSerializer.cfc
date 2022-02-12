component {

	property name="newDocument"    inject="provider:Document@cbelasticsearch";
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="settingService" inject="settingService@contentbox";
	property name="esClient"       inject="Client@cbelasticsearch";
	property name="wirebox"        inject="wirebox";

	/**
	 * Serializes an individual media item with a provided path
	 *
	 * @mediaPath
	 * @memento   an optional memento of fields to add to the serialized document
	 */
	function serialize( required string mediaPath, struct memento = {} ){
		if ( !fileExists( arguments.mediaPath ) ) {
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
				contentType        : "File",
				"featuredImage"    : arguments.mediaPath,
				"featuredImageURL" : mediaURL,
				"blob"             : toBase64( fileReadBinary( arguments.mediaPath ) )
			},
			true
		);

		newDocument()
			.setIndex( moduleSettings.searchIndex )
			.setPipeline( variables.moduleSettings.pipeline )
			.populate( arguments.memento )
			.save();
	}

	/**
	 * Serializes all media in the
	 *
	 * @directory An optional directory to restrict serialization to
	 */
	function serializeAll( directory ){
		var searchPath       = arguments.directory ?: moduleSettings.ingestBaseDirectory;
		var searchExtensions = moduleSettings.ingestExtensionFilter;

		var eligibleMedia = directoryList(
			searchPath,
			true,
			"path",
			searchExtensions,
			"textnocase",
			"file"
		);

		if ( !eligibleMedia.len() ) ;

		// We have to ingest each media item in its own request or we could overload the ES server
		var ops = eligibleMedia.each( function( path ){
			this.serialize(
				path,
				{
					"_id"       : hash( arguments.path ),
					"contentID" : hash( arguments.path ),
					"siteID"    : getSiteIDFromPath( arguments.path )
				}
			);
		} );
	}

	function getSiteIDFromPath( required string path ){
		var mediaDirectory = expandPath( settingService.getSetting( "cb_media_directoryRoot" ) );
		var sitePath       = replace( path, mediaDirectory, "" );
		siteSlug           = listFirst( sitePath );
		var mediaSite      = wirebox
			.getInstance( "SiteService@contentbox" )
			.newCriteria()
			.where( "slug", siteSlug )
			.withProjections( property = "siteID" )
			.asStruct()
			.get();
		return !isNull( mediaSite ) && !structIsEmpty( mediaSite ) ? mediaSite[ "siteID" ] : javacast( "null", 0 );
	}

}

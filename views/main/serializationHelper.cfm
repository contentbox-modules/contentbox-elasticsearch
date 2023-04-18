<cfscript>
	args.mediaDirectory = getInstance( "SettingService@contentbox" ).getSetting( "cb_media_directoryRoot" );
	args.rootDirectory = getController().getAppRootPath();
</cfscript>
<cfoutput>
<script type="application/javascript">
	function serializationComponent(){
		return {
			mediaDirectory : '#args.mediaDirectory#',
			mediaDirectoryExpanded : '#expandPath( args.mediaDirectory )#',
			cbRootDirectory : '#args.rootDirectory#',
			serializationQueue : [],
			isLoading : false,
			isSerializingFile : false,
			isSerializingContent : false,
			ingestMedia : false,
			serializedDbContent: null,
			serializedMedia: null,
			isSerializing( identifier ){
				return this.serializationQueue.findIndex( identifier );
			},
			filters : {
				maxRows : 25,
				scSearch : '',
				smSearch : ''
			},
			loadSnapshot(){
				this.isLoading = true;
				var self = this;
				$.ajax( {
					method: "GET",
					url: '/contentbox-elasticsearch/api/snapshot'
				} ).done(
					( result ) => {
						Object.keys( result.data ).forEach(
							key => {
								if( Array.isArray( result.data[ key ] ) ){
									self[ key ] = result.data[ key ].filter( item => typeof( item.title ) == 'undefined' || item.title.length );
								} else {
									self[ key ] = result.data[ key ];
								}
							}
						);
						self.isLoading = false;
						self.$nextTick(
							() => {
								window.$( "[data-toggle='tooltip']" ).each( function(){
									window.$( this ).tooltip( {
										animation : "slide",
										delay     : { show: 100, hide: 100 }
									} );
								});
							}
						)
					}
				)
			},
			serialize( contentType, identifier, $event ){
				var self = this;
				var serializationType = contentType == 'Media' || contentType == 'File' ? 'File' : 'Content';
				this[ 'isSerializing' + serializationType ] = true;
				if( identifier ){
					this.serializationQueue.push( identifier );
				}
				$.ajax( {
					method: "POST",
					url: '/contentbox-elasticsearch/api/serialize',
					accepts: "application/json",
					contentType: "application/json",
					data: JSON.stringify(
						{
							contentType : contentType,
							contentID : identifier || null
						}
					 )
				} ).done(
					( result ) => {
						self[ 'isSerializing' + serializationType ] = false;
						if( identifier ){
							self.serializationQueue.splice( self.serializationQueue.indexOf( identifier ), 1 );
							switch( serializationType ){
								case 'Content':
									self.serializedDbContent.push( result.data );
									break;
								case 'File':
									self.serializedMedia.push( result.data );
									break;
							}
						} else {
							if( contentType == 'Content' ){
								self.loadSnapshot();
							} else {
								self.serializedMedia = result.data;
							}
						}

					}
				).fail( ( err ) => console.error( err ) )
			},
			unserialize( contentType, identifier, $event ){
				var self = this;
				var serializationType = contentType == 'Media' || contentType == 'File' ? 'File' : 'Content';
				this[ 'isSerializing' + serializationType ] = true;
				if( identifier ){
					this.serializationQueue.push( identifier );
				}
				$.ajax( {
					method: "DELETE",
					url: '/contentbox-elasticsearch/api/serialize',
					accepts: "application/json",
					contentType: "application/json",
					data: JSON.stringify(
						{
							contentType : contentType,
							contentID : identifier
						}
					)
				} ).done(
					( result ) => {
						self[ 'isSerializing' + serializationType ] = false;
						if( identifier ){
							self.serializationQueue.splice( self.serializationQueue.indexOf( identifier ), 1 );
						}
						console.log( serializationType );
						console.log( identifier );
						console.log( self.serializedMedia[ self.serializedMedia.findIndex( item => item.contentID == identifier ) ] );
						console.log( self.serializedMedia.findIndex( item => item.contentID == identifier ) );
						switch( serializationType ){
							case 'Content':
								self.serializedDbContent.splice( self.serializedDbContent.findIndex( item => item.contentID == identifier ), 1 );
								break;
							case 'File':
								self.serializedMedia.splice( self.serializedMedia.findIndex( item => item.contentID == identifier ), 1 );
								break;
						}
					}
				).fail( ( err ) => console.error( err ) )
			},
			filteredDBContent(){
				return this.serializedDbContent.filter( item => item.title.toLowerCase().indexOf( this.filters.scSearch.toLowerCase() ) != -1 ).sort( ( a, b ) => a.title.localeCompare( b.title ) );
			},
			unserializedDbContent(){
				return this.eligibleDbContent.filter( item => this.serializedDbContent.findIndex( ser => ser.contentID == item.contentID ) == -1 && item.title.toLowerCase().indexOf( this.filters.scSearch.toLowerCase() ) != -1 ).sort( ( a, b ) => a.title.localeCompare( b.title ) );
			},
			filteredMediaContent(){
				return this.serializedMedia.filter( item => item.featuredImage.toLowerCase().indexOf( this.filters.smSearch.toLowerCase() ) != -1 ).sort( ( a, b ) => a.featuredImage.split( '\/' ).pop().localeCompare( b.featuredImage.split( '\/' ).pop() ) );
			},
			unserializedMedia(){
				return this.eligibleMedia.filter( file => this.serializedMedia.findIndex( ser => ser.featuredImage == file ) == -1 && file.indexOf( this.filters.smSearch.toLowerCase() ) != -1 ).sort( ( a, b ) => a.split( '\/' ).pop().localeCompare( b.split( '\/' ).pop() ) );
			},
			mediaHref( filePath ){
				return filePath.replace( this.mediaDirectoryExpanded, '/__media' ).replace( this.mediaDirectory, '/__media' ).replace( this.cbRootDirectory, '/' );
			},
			spinThis( e ){
				var $icon = window.$( e.target ).hasClass( 'fa' ) ? window.$( e.target ) : window.$( "i.fa", window.$( e.target ) );
				if( !$icon.hasClass( 'fa-spin' ) ){
					var baseClasses = $icon.attr('class');
					$icon.removeClass( baseClasses ).addClass( 'fa fa-spin fa-spinner' );
					setTimeout( () => $icon.removeClass( 'fa fa-spin fa-spinner' ).addClass( baseClasses ), 1000 );
				}

			}
		}
	}
</script>
</cfoutput>
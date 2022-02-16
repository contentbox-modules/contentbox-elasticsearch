<cfscript>
	args.mediaDirectory = getInstance( "SettingService@contentbox" ).getSetting( "cb_media_directoryRoot" );
</cfscript>
<cfoutput>
<script type="application/javascript">
	function serializationComponent(){
		return {
			mediaDirectory : '#args.mediaDirectory#',
			mediaDirectoryExpanded : '#expandPath( args.mediaDirectory )#',
			serializationQueue : [],
			isLoading : false,
			isSerializingMedia : false,
			isSerializingContent : true,
			ingestMedia : false,
			isSerializing( identifier ){
				return this.serializationQueue.findIndex( identifier );
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
								self[ key ] = result.data[ key ];
							}
						);
						self.isLoading = false;
						self.$nextTick(
							() => window.$( "[data-toggle='tooltip']" ).each( function(){
								window.$( this ).tooltip( {
									animation : "slide",
									delay     : { show: 100, hide: 100 }
								} );
							})
						)
					}
				)
			},
			serialize( contentType, identifier ){
				var self = this;
				this[ 'isSerializing' + contentType ] = true;
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
						self[ 'isSerializing' + contentType ] = false;

						if( identifier ){
							self.serializationQueue.splice( self.serializationQueue.indexOf( identifier ), 1 );
						}
						self.loadSnapshot();
					}
				).fail( ( err ) => console.error( err ) )
			},
			unserialize( contentType, identifier ){
				var self = this;
				this[ 'isSerializing' + contentType ] = true;
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
						self[ 'isSerializing' + contentType ] = false;
						if( identifier ){
							self.serializationQueue.splice( self.serializationQueue.indexOf( identifier ), 1 );
						}
						self.loadSnapshot();
					}
				).fail( ( err ) => console.error( err ) )
			},
			unserializedDbContent(){
				return this.eligibleDbContent.filter( item => this.serializedDbContent.findIndex( ser => ser.contentID == item.contentID ) == -1 );
			},
			unserializedMedia(){
				return this.eligibleMedia.filter( file => this.serializedMedia.findIndex( ser => ser.featuredImage == file ) == -1 );
			},
			mediaHref( filePath ){
				return filePath.replace( this.mediaDirectoryExpanded, '/__media' ).replace( this.mediaDirectory, '/__media' );
			}
		}
	}
</script>
</cfoutput>
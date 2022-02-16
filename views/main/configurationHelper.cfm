<cfscript>
	args.settingService = getInstance( "SettingService@contentbox" );
	args.searchAdapter = args.settingService.findWhere( criteria={ name : "cb_search_adapter", isCore : true } ).getValue();
</cfscript>
<cfoutput>
<script>
	function configComponent(){
		return {
			isSaving : false,
			isLoading : false,
			isUpdated : false,
			isAdapterConfigured: #( findNoCase( '@escontentbox', args.searchAdapter ) ? 'true' : 'false' )#,
			settings: #getInstance( "Util@cbelasticsearch" ).toJSON( getModuleSettings( "contentbox-elasticsearch" ) )#,
			validateAndSubmit : function( form ){
				this.isUpdated = false;
				this.isSaving = true;
				$.ajax( {
					method: "PUT",
					url: '/contentbox-elasticsearch/api/settings',
					accepts: "application/json",
					contentType: "application/json",
					data: JSON.stringify( this.settings )
				} ).done(
					( result ) => {
						// reload our app
						$.ajax({
							method : "POST",
							url : '/cbadmin/dashboard/reload',
							data : { targetModule : "app" }
						});
						this.isUpdated = true;
						this.isSaving = false;
					}
				).fail( ( err ) => console.error( err ) )
			},
			updateSearchAdapter : function(){
				var self = this;
				$.ajax( {
					method: "PATCH",
					url: '/contentbox-elasticsearch/api/adapter'
				} ).always( function( result ){
					self.isAdapterConfigured = true;
				} );
			}
		}
	}
</script>
</cfoutput>
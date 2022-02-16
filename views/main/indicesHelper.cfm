<cfscript>

</cfscript>
<cfoutput>
<script type="application/javascript">
	function indicesComponent(){
		return {
			indexMap : null,
			loadIndices(){
				var self = this;
				$.ajax( {
					method: "GET",
					url: '/contentbox-elasticsearch/api/indices'
				} ).done( ( result ) => {
					self.indexMap = result.data;
				} ).fail( err => console.err( err ) );
			}
		}
	}
</script>
</cfoutput>
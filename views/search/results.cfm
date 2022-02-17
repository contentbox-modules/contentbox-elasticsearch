<cfoutput>
<div class="searchResults">
	#cb.quickSearchPaging()#
	<cfloop array="#args.results.getResults()#" index="i" item="result">
		<div class="panel panel-default">
			<div class="panel-heading">
				<h4>
					<a href="/#result.slug#" class="panel-title">#highlightSearchTerm( args.results.getSearchTerm(), result.title )#</a>
					<cfif result.contentType == 'File'>
						<cfscript>
							switch( listLast( lcase( result.featuredImageURL ), "." ) ){
								case "doc":
								case "docx":{
									faClass = 'fa-file-word';
									break;
								}
								case "mp4":
								case "mov":{
									faClass = 'fa-video';
									break;
								}
								default:{
									faClass = 'fa-file-pdf';
								}
							}
						</cfscript>
						<i class="far fa-lg #faClass# pull-right"></i>
					</cfif>
				</h4>
			</div>
			<div class="panel-body">
				<p>
					<cfif result.contentType != "File" && structKeyExists( result, "featuredImageURL" ) && len( result.featuredImageURL ) >
						<img class="image-responsive hidden-xs" style="float:left; margin-right: 15px; margin-bottom: 15px; max-height:80px; max-width: 80px"  src="#result.featuredImageURL#">
					</cfif>
					#highlightSearchTerm( args.results.getSearchTerm(), truncate( text=stripHTML( !isNull( result.excerpt ) && len( result.excerpt ) ? result.excerpt : result.content ), stop=100, delimiter=" " ) )#
				</p>
			</div>
			<cfif result.categories.len()>
				<div class="panel-footer">
					<cite>Categories:
						<cfloop array="#result.categories#" item="category"><span class="label label-primary">#category#</span></cfloop>
					</cite>
				</div>
			</cfif>
		</div>
	</cfloop>
</div>
</cfoutput>
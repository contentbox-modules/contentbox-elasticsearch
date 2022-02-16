<cfoutput>
<div class="searchResults">
	#cb.quickSearchPaging()#
	<cfloop array="#args.results.getResults()#" index="i" item="result">
		<div class="panel panel-default">
			<div class="panel-heading">
			<a href="/#result.slug#" class="panel-title">#result.title#</a>
			</div>
			<div class="panel-body">
				<p>#highlightSearchTerm( args.results.getSearchTerm(), truncate( text=stripHTML( !isNull( result.excerpt ) && len( result.excerpt ) ? result.excerpt : result.content ), stop=100, delimiter=" " ) )#</p>
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
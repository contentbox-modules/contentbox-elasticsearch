<cfoutput>
<div class="searchResults">
	#cb.quickSearchPaging()#
	<cfloop array="#args.results.getResults()#" index="i" item="result">
		<div class="panel panel-default">
			<div class="panel-heading">
			<a href="/#result.slug#" class="panel-title">#item.title#</a>
			</div>
			<div class="panel-body">
				<p>#highlightSearchTerm( searchTerm, truncate( text=stripHTML( len( item.excerpt ) ? item.excerpt : item.content ), stop=30, delimiter=" " ) )#</p>
			</div>
			<cfif result.categories.len()>
				<div class="panel-footer">
					<cite>Categories:
						<cfloop array="#results.categories#" item="category"><span class="label label-primary">#category#</span></cfloop>
					</cite>
				</div>
			</cfif>
		</div>
	</cfloop>
</div>
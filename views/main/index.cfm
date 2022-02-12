<cfoutput>
	#getInstance( "Processor@cbmarkdown" ).toHTML( fileRead( expandPath( "/escontentbox/README.md" ) ) )#
	<ul class="list-unstyled text-center">
		<li><a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.configuration" )#">Configuration</a></li>
		<li><a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.indices" )#">Indexing</a></li>
		<li><a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.metrics" )#">Metrics</a></li>
	</ul>
</cfoutput>
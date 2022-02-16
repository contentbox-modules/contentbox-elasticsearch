<cfscript>
	adminMenuService = getInstance( "AdminMenuService@contentbox");
</cfscript>
<cfoutput>
	<ul class="nav navbar nav-pills nav-justified">
		<li class="#(rc.moduleAction == "index" ? 'active' : '' )#">
			<a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.index" )#">Module Home</a></li>
		<li class="#(rc.moduleAction == "configuration" ? 'active' : '' )#"><a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.configuration" )#">Configuration</a>
		</li>
		<li class="#(rc.moduleAction == "serialization" ? 'active' : '' )#">
			<a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.serialization" )#">Serialization</a>
		</li>
		<li class="#(rc.moduleAction == "indices" ? 'active' : '' )#">
			<a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.indices" )#">Indexing</a>
		</li>
	</ul>
</cfoutput>
<cfscript>
	adminMenuService = getInstance( "AdminMenuService@contentbox");
</cfscript>
<cfoutput>
	<ul class="nav navbar nav-pills nav-justified">
		<li class="#(rc.moduleAction == "index" ? 'active' : '' )#">
			<a href="#adminMenuService.buildModuleLink( "contentbox-elasticsearch", "Main.index" )#">Module Home</a></li>
		<li class="#(rc.moduleAction == "configuration" ? 'active' : '' )#"><a href="#adminMenuService.buildModuleLink( module="contentbox-elasticsearch", to="Main.configuration", ssl=event.isSSL() )#">Configuration</a>
		</li>
		<li class="#(rc.moduleAction == "serialization" ? 'active' : '' )#">
			<a href="#adminMenuService.buildModuleLink( module="contentbox-elasticsearch", to="Main.serialization", ssl=event.isSSL() )#">Serialization</a>
		</li>
		<li class="#(rc.moduleAction == "indices" ? 'active' : '' )#">
			<a href="#adminMenuService.buildModuleLink( module="contentbox-elasticsearch", to="Main.indices", ssl=event.isSSL() )#">Indexing</a>
		</li>
	</ul>
</cfoutput>
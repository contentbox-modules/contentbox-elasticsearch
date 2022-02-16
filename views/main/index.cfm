<cfoutput>
	#renderView( view="main/inc/adminNav", module="contentbox-elasticsearch" )#
	<div class="row">
		<div class="col-md-12">
			<div class="panel panel-default">
				<!--- Panel Content --->
				<div class="panel-body">
					#getInstance( "Processor@cbmarkdown" ).toHTML( fileRead( expandPath( "/escontentbox/README.md" ) ) )#
				</div>
			</div>
		</div>
	</div>
</cfoutput>
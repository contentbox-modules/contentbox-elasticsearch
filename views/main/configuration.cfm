<cfoutput>
	#renderView( view="main/inc/adminNav", module="contentbox-elasticsearch" )#

	<!--- Setup alpine component --->
	<div x-data="configComponent()">

		<!--- TITLE --->
		<div class="row">
			<div class="col-md-12">
				<h1 class="h1">
					<i class="fas fa-search fa-xs text-muted"></i> Elasticsearch Configuration
				</h1>
			</div>
		</div>

		<!--- MESSAGES --->
		<div class="row">
			<div class="col-md-12">
				<!--- MessageBox --->
				#cbMessageBox().renderit()#
			</div>
		</div>

		<!--- DATA TABLES --->
		<div class="row">
			<div class="col-md-12">
				<div class="panel panel-default">
					<!--- Panel Content --->
					<div class="panel-body" x-cloak>
						<!--- Loader --->
						<div class="text-center m20" x-show="isLoading">
							<i class="fas fa-spinner fa-spin fa-lg"></i><br/>
						</div>
						<div class="col-md-8 col-md-offset-2" x-show="!isAdapterConfigured">
							<div class="alert alert-warning text-center">
								<p>The Elasticsearch search adapter has not yet assigned for this ContentBox Instance.  Would you like to change that setting now?</p>
								<button type="button" class="btn btn-primary" @click="updateSearchAdapter"><i class="fa fa-check"></i> Yes, Update the Configuration</button>
							</div>
						</div>

						<form name="esContentBox_settings" @submit.prevent="validateAndSubmit">

							<div class="col-xs-10 col-xs-offset-1">
								<legend>Search Indexing Configuration</legend>

								<div class="form-group row container">
									<label for="slug" class="control-label">Search Index Alias:</label>
									<input type="text" class="form-control" x-model="settings.searchIndex"/>
									<small class="text-muted">The alias of the search index to create. The actual name of the aliased index will contain this alias, plus this module's version.</small>
								</div>

								<div class="form-group row container">
									<label for="slug" class="control-label">Pipeline Label:</label>
									<input type="text" class="form-control" x-model="settings.pipeline"/>
									<small class="text-muted">The label of the ingest pipeline to create in your Elasticsearch server</small>
								</div>

								<div class="form-group row container">
									<label for="slug" class="control-label">Index Content Types:</label>
									<input
										type="text" class="form-control"
										x-ref="contentTypes"
										x-bind:value="settings.contentTypes.join( ',' )"
										x-on:change="settings.contentTypes = $refs.contentTypes.value.split( ',' )"
									/>
									<small class="text-muted">A list of ContentBox content types to index for search</small>
								</div>

								<div class="form-group row container">
									<label for="slug" class="control-label">Ingest Media:</label>
									<div class="controls">
										<label class="control-label" class="radio inline">
											<input
												type="radio"
												x-bind:value="true"
												name="ingestMedia"
												x-bind:checked="settings.ingestMedia"
												x-on:click="settings.ingestMedia = true"
											>
										</label> Yes

										<label class="control-label" class="radio inline">
											<input
												type="radio"
												x-bind:value="false"
												name="ingestMedia"
												x-bind:checked="!settings.ingestMedia"
												x-on:click="settings.ingestMedia = false"
											> No
										</label>
									</div>
									<small class="text-muted">Whether to enable the ingest and searching of media, specified by the filter and path below</small>
								</div>

								<div class="form-group row container">
									<label for="slug" class="control-label">Ingest Extension Filter:</label>
									<input type="text" class="form-control" x-model="settings.ingestExtensionFilter">
									<small class="text-muted">Specifies the <a href="https://cfdocs.org/cfdirectory" target="_blank">extension filter</a> to use for the directory listing</small>
								</div>

								<div class="form-group row container">
									<label for="slug" class="control-label">Ingest Base Directory:</label>
									<input type="text" class="form-control" x-model="settings.ingestBaseDirectory">
									<small class="text-muted">The directory path, mapped or relative from the root to use to search for ingest-able media</small>
								</div>

							</div>
							<div class="clearfix"></div>
							<div class="col-xs-10 col-xs-offset-1">
								<legend>Search Results - View Settings</legend>
								<div class="form-group row container">
									<label for="slug" class="control-label">Search Results Template:</label>
									<input type="text" class="form-control" x-model="settings.resultsTemplate.view">
									<small class="text-muted">The view to render ( exclude the <code>.cfm</code> extension )</small>
								</div>
								<div class="form-group row container" v-show="!settings.resultsTemplate.isThemeView">
									<label for="slug" class="control-label">Use Theme View:</label>
									<div class="controls">
										<label class="control-label" class="radio inline">
											<input
												type="radio"
												x-bind:value="true"
												name="themeView"
												x-bind:checked="settings.resultsTemplate.isThemeView"
												x-on:click="settings.resultsTemplate.isThemeView = true"
											>
										</label> Yes

										<label class="control-label" class="radio inline">
											<input
												type="radio"
												x-bind:value="false"
												name="themeView"
												x-bind:checked="!settings.resultsTemplate.isThemeView"
												x-on:click="settings.resultsTemplate.isThemeView = false"
											> No
										</label>
									</div>
									<small class="text-muted">Custom search result template settings.  Use to override the results formatting and display.</small>
								</div>
								<div class="form-group row container" v-show="!settings.resultsTemplate.isThemeView">
									<label for="slug" class="control-label">Template Module:</label>
									<input type="text" class="form-control" x-model="settings.resultsTemplate.module">
									<small class="text-muted">If your view is not within your theme, specify the module here, or leave blank to use the root views directory.</small>
								</div>
							</div>
							<div class="clearfix"></div>
							<div class="col-md-4 col-md-offset-4 text-center mt20">
								<button type="submit" class="btn btn-primary">Save Module Configuration</button>
							</div>

						</form>

					</div>
				</div>
			</div>
		</div>

	</cfoutput>
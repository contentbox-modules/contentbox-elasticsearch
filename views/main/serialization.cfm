<cfoutput>
#renderView( view="main/inc/adminNav", module="contentbox-elasticsearch" )#
<div x-data="serializationComponent()">
	<!--- TITLE --->
	<div class="row">
		<div class="col-md-12">
			<h1 class="h1">
				<i class="fas fa-search fa-xs text-muted"></i> Serialization Manager
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
				<div class="panel-body" x-cloak x-init="loadSnapshot()">
					<!--- Loader --->
					<template x-if="isLoading">
						<div class="text-center m20">
							<i class="fas fa-spinner fa-spin fa-lg"></i> Loading serialization information...<br/>
						</div>
					</template>
					<template x-if="!isLoading">
						<div class="row">
							<div class="col-xs-12">
								<h2>ContentBox Content Serialization</h2>
								<div class="col-md-12" id="serialization-data">
									<h3 class="text-muted">Serialization Statistics</h3>
									<div>
										<ul class="list-unstyled col-md-3">
											<li><strong>Content Items in Database:</strong> <span x-text="dbContentCount"></span></li>
											<li><strong>Serialized Content Items:</strong> <span x-text="esContentCount"></span></li>
											<li><strong>Content Missing from Index:</strong> <span x-text="dbContentCount-esContentCount"></span></li>
										</ul>
										<template x-if="ingestMedia">
											<ul class="list-unstyled">
												<li><strong>Eligible Media in File System:</strong> <span x-text="eligibleMedia.length"></span></li>
												<li><strong>Serialized Media Items:</strong> <span x-text="esMediaCount"></span></li>
												<li><strong>Media Items Missing from Index:</strong> <span x-text="eligibleMedia.length-esMediaCount"></span></li>
											</ul>
										</template>
									</div>
									<div>
										<ul class="nav nav-tabs" role="tablist">
											<li class="nav-item">
												<a class="nav-link" id="sc-tab active" data-toggle="tab" data-target="##serialized-content" role="tab" aria-controls="serialized-content">Serialized ContentBox Content</a>
											</li>
											<li class="nav-item" role="presentation">
												<a class="nav-link" id="usc-tab" data-toggle="tab" data-target="##unserialized-content" role="tab" aria-controls="unserialized-content" aria-selected="true">Unserialized Content Items</a>
											</li>
											<li x-show="ingestMedia" class="nav-item" role="presentation">
												<a class="nav-link" id="sm-tab" data-toggle="tab" data-target="##serialized-media" role="tab" aria-controls="serialized-media">Serialized Media</a>
											</li>
											<li x-show="ingestMedia" class="nav-item" role="presentation">
												<a class="nav-link" id="usm-tab" data-toggle="tab" data-target="##unserialized-media" role="tab" aria-controls="unserialized-media" aria-selected="true">Unserialized Media</a>
											</li>
										</ul>
										<div class="tab-content col-xs-12">
											<div role="tabpanel" class="tab-pane active" id="serialized-content" style="padding-top:10px">
												<div class="row">
													<div class="col-sm-6 col-sm-offset-6 col-md-4 col-md-offset-8">
														<div id="serialized-content-table_filter" class="dataTables_filter">
															<div class="input-group">
																<input type="search" class="form-control" name="serialized-content-search" @blur="setTimeout( () => filters.scSearch=$event.target.value, 200 )" placeholder="Enter Term to Search" x-bind:value="filters.scSearch">
																<span class="input-group-btn">
																  <a class="btn btn-default" @click="spinThis"><i class="fa fa-search" @click="spinThis" data-toggle="tooltip" title="Click to Search"></i></a>
																</span>
															</div>
															<label></label>
														</div>
													</div>
												</div>
												<table class="table table-striped table-hover" id="serialized-content-table">
													<thead>
														<tr>
															<th>Content Title</th>
															<th>Content Type</th>
															<th><span class="sr-only">Options</span></th>
														</tr>
													</thead>
													<tbody>
														<template x-for="( contentItem ) in filteredDBContent()">
															<tr>
																<td><a x-bind:href="'/'+contentItem.slug" x-text="contentItem.title" target="_blank"></a></td>
																<td x-text="contentItem.contentType"></td>
																<td style="white-space:nowrap">
																	<a @click="serialize( contentItem.contentType, contentItem.contentID );spinThis( $event )" class="text-muted"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Re-Serialize ' + contentItem.title"></i></a>
																	<a @click="unserialize( contentItem.contentType, contentItem.contentID );spinThis( $event )" class="text-muted"><i class="fa fa-trash" data-toggle="tooltip" title="Delete this Content item from the index"></i></a>
																</td>
															</tr>
														</template>
														<template x-if="!serializedDbContent.length">
															<tr>
																<td colspan="3">
																	<div class="alert alert-warning text-center">
																		<p>
																			No content has yet been serialized to the Elasticsearch index.  Would you like to serialize all content items now?
																		</p>
																		<button type="button" class="btn btn-primary" @click="serialize( 'Content' )">
																			<i class="fa" x-bind:class="{ 'fa-spin fa-spinner' : isSerializingContent, 'fa-upload' : !isSerializingContent }"></i>
																			Yes, Serialize All Content Now
																		</button>
																	</div>
																</td>
															</tr>
														</template>
													</tbody>
												</table>
											</div>
											<div role="tabpanel" class="tab-pane" id="unserialized-content" style="padding-top:10px">
												<div class="row">
													<div class="col-sm-6 col-sm-offset-6 col-md-4 col-md-offset-8">
														<div id="serialized-content-table_filter" class="dataTables_filter">
															<div class="input-group">
																<input type="search" class="form-control" name="unserialized-content-search" @blur="setTimeout( () => filters.scSearch=$event.target.value, 200 )" placeholder="Enter Term to Search" x-bind:value="filters.scSearch"/>
																<span class="input-group-btn">
																  <a class="btn btn-default" @click="spinThis"><i class="fa fa-search" @click="spinThis" data-toggle="tooltip" title="Click to Search"></i></a>
																</span>
															</div>
															<label></label>
														</div>
													</div>
												</div>
												<table class="table table-striped table-hover" id="unserialized-content-table">
													<thead>
														<tr>
															<th>Content Title</th>
															<th>Content Type</th>
															<th><span class="sr-only">Options</span></th>
														</tr>
													</thead>
													<tbody>
														<template x-for="( contentItem ) in unserializedDbContent()">
															<tr>
																<td><a x-bind:href="'/'+contentItem.slug" x-text="contentItem.title" target="_blank"></a></td>
																<td x-text="contentItem.contentType"></td>
																<td style="white-space:nowrap"><a @click="serialize( 'Content', contentItem.contentID )"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Serialize' + contentItem.title"></i></a></td>
															</tr>
														</template>
														<template x-if="!serializedDbContent.length">
															<tr>
																<td colspan="3">
																	<p class="alert alert-success text-center">
																		Congratulations!  All content has currently been serialized to the Elasticsearch index.
																	</p>
																</td>
															</tr>
														</template>
													</tbody>
												</table>
											</div>
											<div x-show="ingestMedia" role="tabpanel" class="tab-pane" id="serialized-media" style="padding-top:10px">
												<div class="row">
													<div class="col-sm-6 col-sm-offset-6 col-md-4 col-md-offset-8">
														<div id="serialized-content-table_filter" class="dataTables_filter">
															<div class="input-group">
																<input type="search" class="form-control" name="serialized-media-search" @blur="setTimeout( () => filters.smSearch=$event.target.value, 200 )" placeholder="Enter Term to Search" x-bind:value="filters.smSearch"/>
																<span class="input-group-btn">
																  <a class="btn btn-default" @click="spinThis"><i class="fa fa-search" @click="spinThis" data-toggle="tooltip" title="Click to Search"></i></a>
																</span>
															</div>
															<label></label>
														</div>
													</div>
												</div>
												<table class="table table-striped table-hover">
													<thead>
														<tr>
															<th>Content Title</th>
															<th>Content Type</th>
															<th><span class="sr-only">Options</span></th>
														</tr>
													</thead>
													<tbody>
														<template x-for="( mediaItem ) in filteredMediaContent()">
															<tr>
																<td><a x-bind:href="'/'+mediaItem.slug" x-text="mediaItem.featuredImage.split( '\/' ).pop()" target="_blank"></a></td>
																<td x-text="mediaItem.featuredImage.split( '\/' ).pop().split( '.' ).pop().toUpperCase()"></td>
																<td style="white-space:nowrap">
																	<a @click="serialize( mediaItem.contentType, mediaItem.featuredImage );spinThis( $event )" class="text-muted"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Re-Serialize ' + mediaItem.featuredImage.split( '\/' ).pop()"></i></a>
																	<a @click="unserialize( mediaItem.contentType, mediaItem.contentID );spinThis( $event )" class="text-muted"><i class="fa fa-trash" data-toggle="tooltip" title="Delete this file from the index"></i></a>
																</td>
															</tr>
														</template>
														<template x-if="!serializedMedia.length">
															<tr>
																<td colspan="3">
																	<p class="text-muted"><em>No media items are currently serialized in the index.</em></p>
																	<template x-if="eligibleMedia.length">
																		<div class="alert alert-warning text-center">
																			<p>
																				Would you like to serialize all <span x-text="eligibleMedia.length"></span> media items now?
																			</p>
																			<button type="button" class="btn btn-primary" @click="serialize( 'File' )">
																				<i class="fa" x-bind:class="{ 'fa-spin fa-spinner' : isSerializingFile, 'fa-upload' : !isSerializingFile }"></i>
																				Yes, Serialize All Media Now
																			</button>
																		</div>
																	</template>
																</td>
															</tr>
														</template>
													</tbody>
												</table>
											</div>
											<div x-show="ingestMedia" role="tabpanel" class="tab-pane" id="unserialized-media" style="padding-top:10px">
												<div class="row">
													<div class="col-sm-6 col-sm-offset-6 col-md-4 col-md-offset-8">
														<div id="serialized-content-table_filter" class="dataTables_filter">
															<div class="input-group">
																<input type="search" class="form-control" name="serialized-media-search" @blur="setTimeout( () => filters.smSearch=$event.target.value, 200 )" placeholder="Enter Term to Search" x-bind:value="filters.smSearch"/>
																<span class="input-group-btn">
																  <a class="btn btn-default" @click="spinThis"><i class="fa fa-search" @click="spinThis" data-toggle="tooltip" title="Click to Search"></i></a>
																</span>
															</div>
															<label></label>
														</div>
													</div>
												</div>
												<table class="table table-striped table-hover">
													<thead>
														<tr>
															<th>Content Title</th>
															<th>Content Type</th>
															<th><span class="sr-only">Options</span></th>
														</tr>
													</thead>
													<tbody>
														<template x-for="( file ) in unserializedMedia()">
															<tr>
																<td><a x-bind:href="mediaHref( file )" x-text="file.split( '\/' ).pop()" target="_blank"></a></td>
																<td x-text="file.split( '\/' ).pop().split( '.' ).pop().toUpperCase()"></td>
																<td><a @click="serialize( 'File', file );spinThis( $event )"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Serialize' + file"></i></a></td>
															</tr>
														</template>
														<template x-if="!unserializedMedia().length">
															<tr>
																<td colspan="3">
																	<p class="alert alert-success text-center">
																		Congratulations!  All media has currently been serialized to the Elasticsearch index.
																	</p>
																</td>
															</tr>
														</template>
													</tbody>
												</table>
											</div>
										</div>
									</div>
								</div>
							</div>
					</template>
				</div>
			</div>
		</div>
	</div>
</div>
</cfoutput>
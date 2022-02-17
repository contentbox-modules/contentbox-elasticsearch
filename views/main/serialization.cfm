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
								<div class="col-md-4">
									<h3 class="text-muted">Serialization Statistics</h3>
									<ul class="list-unstyled">
										<li><strong>Content Items in Database:</strong> <span x-text="dbContentCount"></span></li>
										<li><strong>Serialized Content Items:</strong> <span x-text="esContentCount"></span></li>
										<li><strong>Content Missing from Index:</strong> <span x-text="dbContentCount-esContentCount"></span></li>
									</ul>
									<template x-if="esContentCount > 0 && unserializedDbContent().length">
										<div>
											<hr>
											<h3 class="text-muted">Unserialized Content Items</h3>
											<table class="table table-striped table-hover">
												<thead>
													<tr>
														<th>Content Title</th>
														<th>Content Type</th>
														<th></th>
													</tr>
												</thead>
												<tbody>
													<template x-for="( contentItem ) in unserializedDbContent()">
														<tr>
															<td><a x-bind:href="'/'+contentItem.slug" x-text="contentItem.title" target="_blank"></a></td>
															<td x-text="contentItem.contentType"></td>
															<td><a @click="serialize( 'Content', contentItem.contentID )"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Serialize' + contentItem.title"></i></a></td>
														</tr>
													</template>
												</tbody>
											</table>
										</div>
									</template>
								</div>
								<div class="col-md-8">
									<h3 class="text-muted">Serialized ContentBox Content</h3>
									<template x-if="esContentCount == 0">
										<div class="alert alert-warning text-center">
											<p>
												No content has yet been serialized to the Elasticsearch index.  Would you like to serialize all content items now?
											</p>
											<button type="button" class="btn btn-primary" @click="serialize( 'Content' )">
												<i class="fa" x-bind:class="{ 'fa-spin fa-spinner' : isSerializingContent, 'fa-upload' : !isSerializingContent }"></i>
												Yes, Serialize All Content Now
											</button>
										</div>
									</template>
									<template x-if="esContentCount">
										<div>
											<table class="table table-striped table-hover">
												<thead>
													<tr>
														<th>Content Title</th>
														<th>Content Type</th>
														<th></th>
													</tr>
												</thead>
												<tbody>
													<template x-for="( contentItem ) in serializedDbContent">
														<tr>
															<td><a x-bind:href="'/'+contentItem.slug" x-text="contentItem.title" target="_blank"></a></td>
															<td x-text="contentItem.contentType"></td>
															<td>
																<a @click="serialize( contentItem.contentType, contentItem.contentID )" class="text-muted"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Re-Serialize ' + contentItem.title"></i></a>
																<a @click="unserialize( contentItem.contentType, contentItem.contentID )" class="text-muted"><i class="fa fa-trash" data-toggle="tooltip" title="Delete this Content item from the index"></i></a>
															</td>
														</tr>
													</template>
													<template x-if="!serializedDbContent.length">
														<tr>
															<td colspan="3"><p class="text-muted"><em>No content items are currently serialized in the index.</em></p></td>
														</tr>
													</template>
												</tbody>
											</table>
										</div>
									</template>
								</div>
							</div>
							<div class="col-xs-12" x-show="ingestMedia">
								<h2>Media and Document Serialization</h2>
								<div class="col-md-4">
									<h3 class="text-muted">Serialization Statistics</h3>
									<ul class="list-unstyled">
										<li><strong>Eligible Media in File System:</strong> <span x-text="eligibleMedia.length"></span></li>
										<li><strong>Serialized Media Items:</strong> <span x-text="esMediaCount"></span></li>
										<li><strong>Media Items Missing from Index:</strong> <span x-text="eligibleMedia.length-esMediaCount"></span></li>
									</ul>
									<template x-if="esMediaCount > 0 && unserializedMedia().length">
										<div>
											<hr>
											<h3 class="text-muted">Unserialized Media</h3>
											<table class="table table-striped table-hover">
												<thead>
													<tr>
														<th>Content Title</th>
														<th>Content Type</th>
														<th></th>
													</tr>
												</thead>
												<tbody>
													<template x-for="( file ) in unserializedMedia()">
														<tr>
															<td><a x-bind:href="mediaHref( file )" x-text="file.split( '\/' ).pop()" target="_blank"></a></td>
															<td x-text="file.split( '\/' ).pop().split( '.' ).pop().toUpperCase()"></td>
															<td><a @click="serialize( 'File', file )"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Serialize' + file"></i></a></td>
														</tr>
													</template>
												</tbody>
											</table>
										</div>
									</template>
								</div>
								<div class="col-md-8">
									<h3 class="text-muted">Serialized Media</h3>
									<template x-if="esMediaCount == 0 && eligibleMedia.length">
										<div class="alert alert-warning text-center">
											<p>
												No media has yet been serialized to the Elasticsearch index.  Would you like to serialize all <span x-text="eligibleMedia.length"></span> media items now?
											</p>
											<button type="button" class="btn btn-primary" @click="serialize( 'File' )">
												<i class="fa" x-bind:class="{ 'fa-spin fa-spinner' : isSerializingFile, 'fa-upload' : !isSerializingFile }"></i>
												Yes, Serialize All Media Now
											</button>
										</div>
									</template>
									<template x-if="esMediaCount">
										<div>
											<table class="table table-striped table-hover">
												<thead>
													<tr>
														<th>Content Title</th>
														<th>Content Type</th>
														<th></th>
													</tr>
												</thead>
												<tbody>
													<template x-for="( mediaItem ) in serializedMedia">
														<tr>
															<td><a x-bind:href="'/'+mediaItem.slug" x-text="mediaItem.featuredImage.split( '\/' ).pop()" target="_blank"></a></td>
															<td x-text="mediaItem.featuredImage.split( '\/' ).pop().split( '.' ).pop().toUpperCase()"></td>
															<td>
																<a @click="serialize( mediaItem.contentType, mediaItem.featuredImage )" class="text-muted"><i class="fa fa-upload" data-toggle="tooltip" x-bind:title="'Re-Serialize ' + mediaItem.featuredImage.split( '\/' ).pop()"></i></a>
																<a @click="unserialize( mediaItem.contentType, mediaItem.contentID )" class="text-muted"><i class="fa fa-trash" data-toggle="tooltip" title="Delete this file from the index"></i></a>
															</td>
														</tr>
													</template>
													<template x-if="!serializedDbContent.length">
														<tr>
															<td colspan="3"><p class="text-muted"><em>No content items are currently serialized in the index.</em></p></td>
														</tr>
													</template>
												</tbody>
											</table>
										</div>
									</template>

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
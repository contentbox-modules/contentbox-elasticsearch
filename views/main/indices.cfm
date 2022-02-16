<cfoutput>
	#renderView( view="main/inc/adminNav", module="contentbox-elasticsearch" )#
	<div x-data="indicesComponent()">

		<!--- TITLE --->
		<div class="row">
			<div class="col-md-12">
				<h1 class="h1">
					<i class="fas fa-search fa-xs text-muted"></i> Elasticsearch Indices And Aliases
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
						<div
							x-init="loadIndices"
							class="col-xs-12"
						>
							<template x-if="indexMap">
								<table id="index-list" class="table table-striped table-hover">
									<thead>
										<tr>
											<th style="width:20%">Index</th>
											<th style="width:20%">Aliases</th>
											<th style="width:10%">Documents</th>
											<th style="width:10%">Storage</th>
											<th style="width:20%">Description</th>
										</tr>
									</thead>
									<tbody>
										<template x-for="( indexData, indexName ) in indexMap">
											<tr>
												<td x-text="indexName"></td>
												<td>
													<template x-if="indexData.aliases.length">
														<ul class="list-unstyled">
															<template x-for="alias in indexData.aliases">
																<li x-text="alias"></li>
															</template>
														</ul>
													</template>
													<template x-else>
														<span x-else><em class="text-muted">None</em></span>
													</template>
												</td>
												<td x-text="indexData.docs"></td>
												<td><span x-text="(indexData.size_in_bytes / 1048576).toFixed( 2 )"></span> MB</td>
												<td>
													<template x-if="indexData.isPrimary">
														<span>
															Primary Index for ContentBox Search
														</span>
													</template>
													<template x-else>
														<span>Unknown/Unassigned Index - not currently in use by ContentBox</span>
													</template>
												</td>
											</tr>
										</template>
									</tbody>
								</table>
							</template>
							<template x-else>
								<p class="text-muted text-center"><i class="fas fa-spinner fa-spin fa-lg"></i> Loading indices data...</p>
							</template>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
	</cfoutput>
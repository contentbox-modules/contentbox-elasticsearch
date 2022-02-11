component {
	property name="mapping" inject="SearchIndexMapping@escontentbox";
	property name="moduleSettings" inject="coldbox:moduleSettings:contentbox-elasticsearch";
	property name="searchClient" inject="Client@cbelasticsearch";
	property name="cache" inject="cachebox:default";

	void function ensureSearchIndex( event, interceptData ){

        cache.getOrSet( "contentBoxSearchIndexAssured", function(){
            lock type="exclusive" name="evaluate_and_create_contentbox_searchIndex" timeout="30" throwontimeout="false"{
				var searchSettings      = variables.mapping.getConfig();
				// the resolvable alias of our search index
				var searchIndexAlias     = variables.moduleSettings.searchIndex;

				//if this check fails, we are unable to connect to Elasticsearch and we need to throw hard
				try{
					var aliasExists = searchClient.getAliases().aliases.keyExists( searchIndexAlias );
					var mappingExists = searchClient.indexMappingExists( searchIndexAlias );
				} catch( any e ){
					// throw a hard error
					throw(
						type="ESContentBox.elasticsearchConnectionException",
						message="A connection to a running Elasticsearch server could not be established.  This module requires a running connection to an elasticsearch server.  Could not continue",
						detail="#serializeJSON( e, false, false )#"
					);
				}

				/**
				* Creation should only occur if there are no aliases detected
				**/
				if( !mappingExists && !aliasExists ){
					var searchIndexName = searchIndexAlias & "_" & reReplace( moduleSettings.version, "[^a-zA-Z0-9]", "_", "all" );

					searchIndexUtil.newSearchIndexBuilder().new(
						name=searchIndexName,
						properties=searchSettings
					).save();

					// now alias our index
					var aliasBuilder = getInstance( "AliasBuilder@cbElasticsearch" ).new( "add", searchIndexName, searchIndexAlias );
					searchClient.applyAliases( aliasBuilder );

				} else if( !mappingExists && aliasExists ){
					log.warn( "An incorrect mapping for alias #searchIndexAlias# was detected or a communication issue with the server prevented the correct response. An attempt is being made to re-apply the mapping to ensure the correct version." );
					try{
						searchClient.applyMapping( searchIndexAlias, "_doc", searchSettings.mappings._doc );
					} catch( any e ){
						log.error( "The attempt to apply an updated mapping for search index alias #searchIndexAlias# failed with the fatal error: #e.message#. The ability to successfully save and search documents may be compromised.", { exception : e } );
					}
				}
            }// end lock
            return now();
        } );

		return this;
    }

    function ensurePipelines( event, interceptData ){
		// ingest pipeline for reports and cases to ensure redactions of media blobs
        var baseProcessor = "
			if( ctx.attachment != null && ctx.attachment.content != null ){
				ctx.content = ctx.attachment.content;
				ctx.title = ctx.attachment.title;
				ctx.creator = ctx.attachment.author;
				ctx.createdDate = ctx.attachment.date + 'T00:00:00+00:00';
				ctx.remove( 'attachment' );
			}
			if( ctx.blob != null ){
				ctx.remove( 'blob' );
			}
        ";

        getInstance( "Pipeline@cbElasticsearch" ).new(
            {
                "id" : variables.moduleSettings.pipeline,
                "description" : "Pipeline for ingesting contentbox content items",
                "version" : 1,
                "processors" : [
                    {
                        "script": {
                            "lang": "painless",
                            "source": reReplace( baseProcessor, "\n|\r|\t", "", "ALL" )
                        }
                    }
                ]
            }
        ).save();



        // media ingest pipeline
		if( moduleSettings.ingestMedia ){
			try{
				getInstance( "Pipeline@cbElasticsearch" ).new(
					{
						"id" : variables.moduleSettings.pipeline & "_media",
						"description" : "Pipeline for ingesting contentbox media for textual search",
						"version" : 1,
						"processors" : [
							{
								"attachment" : {
									"ignore_missing" : true,
									"field" : "blob"
								}
							},
							{
								"script": {
									"lang": "painless",
									"source": reReplace( baseProcessor, "\n|\r|\t", "", "ALL" )
								}
							}
						]
					}
				).save();
			} catch( cbElasticsearch.HyperClient.ApplyPipelineException e ){
				throw(
					type="ESContentBox.Elasticsearch.MissingPluginException",
					message="The pipeline for media ingest could not be applied. ESContentBox requires that the ingest attachment plugin be enabled.  Please see the installation instructions here: https://www.elastic.co/guide/en/elasticsearch/plugins/current/ingest-attachment.html ",
					extendedInfo=e.extendedInfo
				);

			} catch( any e ){
				rethrow;
			}
		}

		return this;

    }
}
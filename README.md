# ContentBox Elasticsearch Search Provider

This contentbox module provides elasticsearch search capabilities for the ContentBox CMS Platform.  With the addition of the [Ingest Attachment Plugin for Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/plugins/current/ingest-attachment.html), it adds capabilities of ingesting PDF, MS Word, and other supported document formats from a directory you specify in the configuration.

## Getting Started

In order to utilize this plugin, a connection to an Elasticsearch server must be established. The [`cbElasticsearch`](https://www.forgebox.io/view/cbelasticsearch) Coldbox module is a dependency of this module and will need to be configured.  The easiest way to do this is through the use of environment variables, which will be picked up and used when the module is installed. See [Configuration via Environment Variables](https://cbelasticsearch.ortusbooks.com/configuration#configuration-via-environment-variables) in the [cbElasticsearch Documentation](https://cbelasticsearch.ortusbooks.com).  You may also add the explicit configuration to your `config/Coldbox.cfc`.  Ideally, this should be done before installing the module, so that the indices may be created on the load of the module. If done after module activation, the framework will require a reinit in order to pick up the changes.

In addition to the Elasticsearch configuration, the module configuration may be updated to specify additional indexing options. The default configuration is as follows:

```lang=json
{
    // The search index alias where the this ContentBox's data will be stored
    "searchIndex" : "contentbox-content",
    // The name of the pipeline used to handle the ingest of documents and media ( if enabled )
    "pipeline" : "contentbox_content",
    // The content types to serialize for search
    "contentTypes" : [ "Page", "Entry" ],
    // Whether to ingest media items
    "ingestMedia" : false,
    // CF directoryList exension filter
    "ingestExtensionFilter" : "*.pdf|*.doc|*.docx",
    // The directory for which to search for ingestable media
    "ingestBaseDirectory" : "/contentbox-custom/_content",
    // The template to use for displaying the search results
    "resultsTemplate" : {
		// The module from which to render the search results template. N/A if isThemeView is true
        "module" : "contentbox-elasticsearch",
		// The template to render search results
        "view" : "search/results",
		// If true, the view will be rendered from your theme views directory
		"isThemeView" : false
    }
}
```

By default, the indexing of media is disabled.  If you wish to enable this, you must first install the [Ingest Attachment Plugin for Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/plugins/current/ingest-attachment.html).  If you are using docker, you may do this using a Dockerfile, like so:

```
FROM docker.elastic.co/elasticsearch/elasticsearch:7.16.3

RUN bin/elasticsearch-plugin install ingest-attachment --batch
```

For all platforms, the `elasticsearch-plugin` binary located in the `/bin` directory of your Elasticsearch installation may be used to install the plugin.

## ContentBox Configuration

Before switching your site over to use Elasticsearch, please review all of the configuration options in in administration section.  If you have elected to serialize media for search, you will want to ensure that all files in the path you have configured are suitable for public search indexing.  Once configuration is complete, save the settings and continue to the next steps.

## Search Adapter

To change the ContentBox Search over to use Elasticsearch data, you must first change the Search Adapter used by ContentBox.  To do this, navigate in the Admin to `System > Settings > Search Options` and set the `Search Adapter` value to `SearchAdapter@escontentbox`.   If you wish to use a different view for your search results, you may do so via customization of the module configuration ( see above ).  The `search/results.cfm` file in the `contentbox-elasticsearch` module will give you a template from which to work.  This module is installed in the `modules/contentbox/modules_user` directory.

## Serialization

By default, when the module is installed and your application is connected to Elasticsearch, the [search index](https://cbelasticsearch.ortusbooks.com/indexes) and [pipelines](https://cbelasticsearch.ortusbooks.com/pipelines) are created, but content is not yet serialized. 

Before the next step, navigate to the "Serialization" area in the Module admin.  You will see a prompt allowing you to serialize all Content items. This will seed the index with all of the ContentBox content ( by default, Blog posts and Pages ) in your system. This is a relatively fast process, but sites with hundreds or thousands of pages, may require a minute or two for this job to complete.

If you have elected to serialize media, you will also see a prompt to serialize all eligible media and it will send all files in your configured directory, which match your extension filters, to Elasticsearch for indexing.

Once your indexes are seeded, ContentBox Content and files, if applicable, will update automatically in the search index as they are created/updated/deleted.  With data in the index, we may now change the Search adapter over to use the Elasticsearch data.  If you wish to de-index an item at any time, you may return to the Elasticsearch admin and remove items from the index.



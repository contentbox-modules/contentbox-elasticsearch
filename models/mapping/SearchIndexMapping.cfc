/**
 * Elasticsearch mapping configuration for notes
 **/
component accessors="true" {

	property name="config";

	/**
	 * The elasticsearch config typing for ContentBox content and media
	 **/
	variables.config = {
		"mappings" : {
			"_doc" : {
				"properties" : {
					"contentID"    : { "type" : "keyword" },
					"parentID"     : { "type" : "keyword" },
					"siteID"       : { "type" : "keyword" },
					"contentType"  : { "type" : "keyword" },
					"slug"         : { "type" : "keyword" },
					"SSLOnly"      : { "type" : "boolean" },
					"isPublished"  : { "type" : "boolean" },
					"isDeleted"    : { "type" : "boolean" },
					"showInSearch" : { "type" : "boolean" },
					"title"        : {
						"type"   : "text",
						"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
					},
					"HTMLDescription" : {
						"type"   : "text",
						"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
					},
					"HTMLKeywords" : { "type" : "text" },
					"HTMLTitle"    : {
						"type"   : "text",
						"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
					},
					"displayOrder"     : { "type" : "integer" },
					"categories"       : { "type" : "keyword" },
					"excerpt"          : { "type" : "text" },
					"content"          : { "type" : "text" },
					"createdDate"      : { "type" : "date", "format" : "date_time_no_millis" },
					"expireDate"       : { "type" : "date", "format" : "date_time_no_millis" },
					"modifiedDate"     : { "type" : "date", "format" : "date_time_no_millis" },
					"publishedDate"    : { "type" : "date", "format" : "date_time_no_millis" },
					"featuredImageURL" : { "type" : "keyword", "ignore_above" : 256 },
					"featuredImage"    : { "type" : "keyword", "ignore_above" : 256 },
					"blob"             : { "type" : "binary" },
					"creator"          : {
						"type"   : "text",
						"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
					},
					"lastEditor" : {
						"type"   : "text",
						"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
					},
					"attachment" : {
						"type"       : "object",
						"properties" : {
							"author" : {
								"type"   : "text",
								"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
							},
							"content"        : { "type" : "text" },
							"content_length" : { "type" : "long" },
							"content_type"   : {
								"type"   : "text",
								"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
							},
							"date"     : { "type" : "date" },
							"language" : {
								"type"   : "text",
								"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
							},
							"title" : {
								"type"   : "text",
								"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
							}
						}
					},
					"meta" : {
						"type"       : "object",
						"properties" : {
							"lastSerializedTime" : { "type" : "date", "format" : "date_time_no_millis" },
							"moduleVersion"      : { "type" : "keyword" },
							"contentBoxVersion"  : { "type" : "keyword" },
							"lazyLoaded"         : { "type" : "boolean" },
							"lastAuditTime"      : { "type" : "date", "format" : "date_time_no_millis" },
							"lastAuditPassed"    : { "type" : "boolean" }
						}
					}
				}
			}
		}
	};

}

# Stardog - A Simple Ruby Client for the Stardog RDF Database

[![Code Climate](https://codeclimate.com/github/pdlug/stardog-ruby.png)](https://codeclimate.com/github/pdlug/stardog-ruby)

This is a very basic wrapper around the Stardog HTTP (REST) API providing basic support for adding/removing/clearing data in a database and querying using SPARQL.

## Getting started

1. Install Stardog and read the [Quick start guide](http://stardog.com/docs/quick-start/)
1. Create a database for testing (we'll use _rubytest_ for the examples below):

    ```
    stardog-admin db create -n rubytest -t D -u admin -p admin
    ```
1. Connect with ruby

    ```
    require 'stardog'
    db = Stardog::Server.new(url: 'http://127.0.0.1:5822')
      .db('rubytest', username: 'admin', password: 'admin')
    ```

1. Load some data

    ```
    rdf_data = File.read(File.expand_path('./test.turtle', File.dirname(__FILE__)))
    db.transaction do
      add(rdf_data, Stardog::Format::TURTLE)
      commit
    end
    ```

1. Try a few queries, query results are returned as an Enumerable of [RDF::Query::Solution](http://rdf.rubyforge.org/RDF/Query/Solution.html) objects.

    ```
    # Find each distinct subject in the database
    db.query('SELECT DISTINCT ?s WHERE { ?s ?p ?o } LIMIT 10').each do |solution|
      puts solution[:s]
    end
    ```

    ```
    # Find out who created Stardog
    db.query(%Q{
      PREFIX dc: <http://purl.org/dc/elements/1.1/>

      SELECT ?name
      WHERE { 
        <http://stardog.com/> dc:creator ?creator .
        ?creator dc:title ?name .
      }
    }).first[:name]
    ```

1. Drop the database

    ```
    stardog-admin db drop rubytest
    ```

## Configuring

The `Stardog::Server` object providers the base wrapper around connections to the server and uses [Faraday](https://github.com/lostisland/faraday) to enable support for multiple HTTP backends. Any of the HTTP client adapters supported by Faraday can be used by specifying them in the `:adapter` parameter (e.g. `Stardog::Server.new(url: ..., adapter: :typhoeus)`). By default the `:net_http` adapter is used since it is built into ruby and requires no external dependencies, please see the note below for some of the limitations with this.

**IMPORTANT NOTE:** Stardog requires that the SD-* headers be specified with the proper capitalization, this does *not* work with the default ruby :net_http adapter. The ruby net/http library normalizes all headers by downcasing them then introducing mixed caps, this turns headers like `SD-Connection-String` into `Sd-Connection-String` and Stardog disgards it (which is wrong, HTTP headers are case insensitive per the spec). For now the only solution is to use an adapter that does not mess with the headers this way, I am successfully using both :excon and :typheous but others may work as well.


## See Also

* [Stardog Documentation](http://stardog.com/docs) - the Stardog docs are awesome, read them.

## TODO

* Comprehensive error handling - not all HTTP errors are currently handled, more detailed error reporting is also possible by examining the `SD-Error-Code` header if present.
* Better SPARQL query result wrapper - the basic Enumerable of RDF::Query::Solution will be replaced with a more robust wrapper for results that will enable more convenience methods.

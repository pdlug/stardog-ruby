# Stardog - A Simple Ruby Client for the Stardog RDF Database

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

    db = Stardog::Database.new(
      url:      'http://127.0.0.1:5822',
      name:     'rubytest',
      username: 'admin',
      password: 'admin'
    )
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

## See Also

* [Stardog Documentation](http://stardog.com/docs) - the Stardog docs are awesome, read them.

## TODO

* Comprehensive error handling - not all HTTP errors are currently handled, more detailed error reporting is also possible by examining the `SD-Error-Code` header if present.
* Better SPARQL query result wrapper - the basic Enumerable of RDF::Query::Solution will be replaced with a more robust wrapper for results that will enable more convenience methods.
Minidusen [![Build Status](https://secure.travis-ci.org/makandra/minidusen.png?branch=master)](https://travis-ci.org/makandra/minidusen)
======

Low-tech search solution for ActiveRecord and MySQL or PostgreSQL
-----------------------------------------------------------------

Minidusen lets you search ActiveRecord model when all you have is MySQL or PostgreSQL (no Solr, Sphinx, etc.). Here's what Minidusen does for you:

1. It takes a text query in Google-like search syntax e.g. `some words "a phrase" filetype:pdf -excluded -"excluded  phrase" filetype:-txt`)
2. It parses the query into individual tokens.
3. It lets you define simple mappers that convert a token to an ActiveRecord scope chain. Mappers can match tokens using ActiveRecord's `where` or perform full text searches with either [LIKE queries](#processing-full-text-search-queries-with-like-queries) or [FULLTEXT indexes](#processing-full-text-queries-with-fulltext-indexes) (see [performance analysis](https://makandracards.com/makandra/12813-performance-analysis-of-mysql-s-fulltext-indexes-and-like-queries-for-full-text-search)).
4. It gives your model a method `Model.search('some query')` that performs all of the above and returns an ActiveRecord scope chain.


Processing full text search queries with LIKE queries
-----------------------------------------------------

This describes how to define a search syntax that processes queries
of words and phrases, e.g. `coworking fooville "market ave"`.

Under the hood the search will be performed using [LIKE queries](http://dev.mysql.com/doc/refman/5.0/en/string-comparison-functions.html#operator_like), which are [fast enough](https://makandracards.com/makandra/12813-performance-analysis-of-mysql-s-fulltext-indexes-and-like-queries-for-full-text-search) for medium sized data sets. Once your data outgrows LIKE queries, Minidusen lets you [migrate to FULLTEXT indexes](#processing-full-text-queries-with-fulltext-indexes), which perform better but come at some added complexity.


### Setup and usage

Our example will be a simple address book:

    class Contact < ActiveRecord::Base
      validates_presence_of :name, :street, :city, :email
    end


In order to teach `Contact` how to process a text query, use the `search_syntax` and `search_by :text` macros:

    class Contact < ActiveRecord::Base

      ...

      search_syntax do

        search_by :text do |scope, phrases|
          columns = [:name, :street, :city, :email]
          scope.where_like(columns => phrases)
        end

      end

    end


Minidusen will tokenize the query into individual phrases and call the `search_by :text` block with it. The block is expected to return a scope that filters by the given phrases.

If, for example, we call `Contact.search('coworking fooville "market ave"')`
the block supplied to `search_by :text` is called with the following arguments:

    |Contact, ['coworking', 'fooville', 'market ave']|


The resulting scope chain is your `Contact` model filtered by
the given query:

     > Contact.search('coworking fooville "market ave"')
    => Contact.where_like([:name, :street, :city, :email] => ['coworking', 'fooville', 'market ave'])

### What where_like does under the hood

Note that `where_like` is an utility method that comes with the Minidusen gem.
It takes one or more column names and one or more phrases and generates an SQL fragment
that looks roughly like the following:

    ( contacts.name LIKE "%coworking%"    OR 
      contacts.street LIKE "%coworking%"  OR 
      contacts.email LIKE "%coworking%"   OR 
      contacts.email LIKE "%coworking%" ) AND
    ( contacts.name LIKE "%fooville%"     OR 
      contacts.street LIKE "%fooville%"   OR 
      contacts.email LIKE "%fooville%"    OR 
      contacts.email LIKE "%fooville%" )  AND
    ( contacts.name LIKE "%market ave%"   OR 
      contacts.street LIKE "%market ave%" OR 
      contacts.email LIKE "%market ave%"  OR 
      contacts.email LIKE "%market ave%" )

You can also use `where_like` to find all the records *not* matching some phrases, using the `:negate` option:

    Contact.where_like({ :name => 'foo' }, { :negate => true })

Processing queries for qualified fields
---------------------------------------

Google supports queries like `filetype:pdf` that filters records by some criteria without performing a full text search. Minidusen gives you a simple way to support such search syntax.

### Setup and usage

We now want to process a qualified query like `email:foo@bar.com` to
explictily search for a contact's email address, without going through
a full text search.

We can learn this syntax by adding a `search_by :email` instruction
to our model:

    search_syntax do

      search_by :text do |scope, phrases|
        ...
      end

      search_by :email do |scope, email|
        scope.where(:email => email)
      end

    end


The result is this:

     > Contact.search('email:foo@bar.com')
    => Contact.where(:email => 'foo@bar.com')


Note that you can combine text tokens and field tokens:

     > Contact.search('fooville email:foo@bar.com')
    => Contact.where_like(columns => 'fooville').where(:email => 'foo@bar.com')
    
### Caveat

If you search for a phrase containing a colon (e.g. `deploy:rollback`), Minidusen
will mistake the first part as a – nonexistent – qualifier and return an empty
set.

To prevent that, prefix your query with the default qualifier `text`:

    text:deploy:rollback



Supported Rails versions
------------------------

Minidusen is tested on:

- Rails 3.2
- Rails 4.2
- Rails 5.0
- MySQL 5.6
- PostgreSQL

If you need support for platforms not listed above, please submit a PR!


Installation
------------

In your `Gemfile` say:

    gem 'minidusen'

Now run `bundle install` and restart your server.


Development
-----------

- Test applications for various Rails versions lives in `spec`.
- You need to create a MySQL database and put credentials into `spec/shared/app_root/config/database.yml`.
- You can bundle all test applications by saying `bundle exec rake all:bundle`
- You can run specs from the project root by saying `bundle exec rake all:spec`.

If you would like to contribute:

- Fork the repository.
- Push your changes **with passing specs**.
- Send me a pull request.

I'm very eager to keep this gem lightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Henning Koch from [makandra](http://makandra.com/)

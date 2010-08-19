require 'indextank/exceptions'
require 'json'

module IndexTank
  class IndexHash < Hash
  end

  class Index
    def initialize(index_url, metadata = nil)
      @conn = IndexTank.setup_connection(index_url)
      @metadata = metadata
    end

    def add
      response = @conn.put('')
      case response.status
      when 201
        true
      when 204
        raise IndexAlreadyExists
      when 409
        raise TooManyIndexes
      end
    end

    def refresh
      response = @conn.get('')
      if response.status == 200
        @metadata = response.body
      end

      response
    end

    def delete
      response = @conn.delete('')
    end

    def running?
      refresh
      @metadata['started']
    end

    def method_missing(sym, *args, &block)
      refresh if @metadata.nil?
      @metadata[sym.to_s]
    end

    def exists?
      refresh.status != 404
    end

    # the options argument may contain an :index_code definition to override 
    # this instance's default index_code
    # it can also contain any of the following:
    #   :start => an int with the number of results to skip
    #   :len => an int with the number of results to return
    #   :snippet => a comma separated list of field names for which a snippet
    #               should be returned. (requires an index that supports snippets)
    #   :fetch => a comma separated list of field names for which its content
    #             should be returned. (requires an index that supports storage)
    #   :function => an int with the index of the scoring function to be used
    #                for this query
    def search(query, options = {})
      options = {:start => 0, :len => 10 }.merge(options).merge(:q => query)
      @conn.get do |req|
        req.url '/search', options
      end.body
    end

    # the options argument may contain an :index_code definition to override 
    # this instance's default index_code  
    def promote(docid, query, options={})
    end
  end
end

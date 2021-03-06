module RunQuery
  include RetryUtils

  # Load query functions
  include IndexQuery
  include RetrieveDataspec
  include SingleDocQuery
  include ThreadQuery
  include AllQuery
  include SearchQuery
  include CountQuery
  include NilQuery
  include RangeQuery
  include TermVectorQuery
  include ExportQuery
  include ChildDocQuery
 
  def query_docs(query_method, *args)
    # Get models for index
    @models = get_all_models_for_project(@index_name) 
    @query_method = query_method
    
    # Calculate return # info
    @return_size = 100
    @return_count = get_return_size

    # Run over docs
    query_block = choose_query_method(*args)
    return query_elastic(query_block)
  end

  # Get the appropriate query method
  def choose_query_method(*args)
    case @query_method
    when "index_page"
      return query_docs_for_index_page(*args)
    when "single_doc"
      return retrieve_single_doc(*args)
    when "thread_query"
      return query_thread(*args)
    when "get_all_docs"
      return query_all
    when "search_query_display"
      return search_query_display(*args)
    when "total_docs"
      return total_doc_count
    when "total_doc_count_for_type"
      return total_doc_count_for_type(*args)
    when "num_docs_in_collection"
      return collection_doc_total(*args)
    when "empty_field"
      return query_docs_with_empty_field(*args)
    when "search_query_catalyst"
      return search_query_catalyst(*args)
    when "search_query_catalyst_count"
      return search_query_catalyst_count(*args)
    when "range_query_catalyst"
      return range_query_catalyst(*args)
    when "range_query_catalyst_count"
      return range_query_catalyst_count(*args)
    when "term_vector_query"
      return term_vector_catalyst(*args)
    when "child_doc"
      return find_children(*args)
    when "docs_to_export"
      return get_docs_to_export(*args)
    end
  end

  # Get the return size
  def get_return_size
    # Set return count to 1 if it should only run once for the query
    only_run_once = ["total_docs", "num_docs_in_collection", "single_doc", "index_page", "search_query_display", "term_vector_query",
                     "range_query_catalyst_count", "search_query_catalyst_count", "total_doc_count_for_type"]
    return nil if only_run_once.include?(@query_method)

    # Otherwise, calculate based on the total num of documents
    total = query_retry(0) {total_doc_count.call}
    return (total/@return_size)+1
  end

  # Runs all queries generated
  def query_elastic(query_block, *args)
    docs = Array.new
    
    # Get the documents in chunks if needed
    if @return_count == nil
      @return_count = 1
      docs = query_retry(0) { query_block.call }
    else
      @return_count.times do |i|
        docs += query_retry(0) { query_block.call(i) }
      end
    end
    
    return docs
  end
end

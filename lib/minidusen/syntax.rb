module Minidusen
  class Syntax

    def initialize
      @scopers = {}
    end

    def learn_field(field, &scoper)
      field = field.to_s
      @scopers[field] = scoper
    end

    def learn_unknown_field(&unknown_scoper)
      @unknown_scoper = unknown_scoper
    end

    def search(root_scope, query)
      query = parse(query) if query.is_a?(String)
      query = query.condensed
      matches = apply_query(root_scope, query.include)
      if query.exclude.any?
        matches = append_excludes(matches, query.exclude)
      end
      matches
    end

    def fields
      @scopers
    end

    def parse(query)
      Parser.parse(query)
    end

    private

    DEFAULT_UNKNOWN_SCOPER = lambda do |scope, *args|
      scope.where('1=2')
    end

    def unknown_scoper
      @unknown_scoper || DEFAULT_UNKNOWN_SCOPER
    end

    def apply_query(root_scope, query)
      scope = root_scope
      query.each do |token|
        scoper = @scopers[token.field] || unknown_scoper
        scope = scoper.call(scope, token.value)
      end
      scope
    end

    def append_excludes(matches, exclude_query)
      # root_scope_without_conditions = root_scope.except(:where)
      # root_scope_without_conditions.bind_values = [] if root_scope_without_conditions.respond_to?(:bind_values=)
      # root_scope_without_conditions = root_scope.origin_class
      excluded_records = apply_query(matches.origin_class, exclude_query)
      qualified_id_field = "#{excluded_records.table_name}.#{excluded_records.primary_key}"
      exclude_sql = "#{qualified_id_field} NOT IN (#{excluded_records.select(qualified_id_field).to_sql})"
      matches.where(exclude_sql)

      # puts "exclude_scope before coalesce: #{exclude_scope.to_sql}"
      #
      # where_clause = exclude_scope.where_clause
      # bind_values = where_clause ? where_clause.binds : []
      #
      # exclude_scope_conditions = concatenate_where_values(exclude_scope.where_values)
      #
      #
      # if exclude_scope_conditions.present?
      #   # byebug if exclude_scope.where_values.present?
      #   false_string = exclude_scope.connection.quoted_false
      #   inverted_sql = "NOT COALESCE (" + exclude_scope_conditions + ", #{false_string})"
      #
      #   # puts "Bind values are #{(bind_values.inspect)}"
      #   # puts "Resulting scope is #{exclude_scope.except(:where).where(inverted_sql, *bind_values).to_sql}"
      #
      #   # rebuilt_scope = exclude_scope.except(:where)
      #
      #   exclude_scope.except(:where).where(inverted_sql, *bind_values)
      #
      #   # rebuilt_scope = exclude_scope
      #   # rebuilt_scope = rebuilt_scope.except(:where)
      #   # rebuilt_scope = rebuilt_scope.where(inverted_sql)
      #   # rebuilt_scope.bind_values = bind_values
      #   # rebuilt_scope
      #
      # else
      #   # unknown_scoper.call(root_scope)
      #   warn "komisch"
      #   root_scope
      # end

    end

    def concatenate_where_values(where_values)
      if where_values.any?
        if where_values[0].is_a?(String)
          first = where_values.shift
          where = where_values.reduce(first) do |result, value|
            result << " AND " << value
          end
          where
        else
          # where_values are AREL-Nodes
          where = where_values.reduce(:and)
          where.to_sql
        end
      end
    end

  end
end

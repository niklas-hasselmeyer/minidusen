# encoding: utf-8

module Dusen
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
      matches = find_parsed_query(root_scope, query.include)
      if query.exclude.any?
        inverted_exclude_scope = build_exclude_scope(root_scope, query.exclude)
        matches.merge(inverted_exclude_scope)
      else
        matches
      end
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

    def find_parsed_query(root_scope, query)
      scope = root_scope
      query.each do |token|
        scoper = @scopers[token.field] || unknown_scoper
        scope = scoper.call(scope, token.value)
      end
      scope
    end

    def build_exclude_scope(root_scope, exclude_query)
      root_scope_without_conditions = root_scope.except(:where)
      root_scope_without_conditions.bind_values = []
      exclude_scope = find_parsed_query(root_scope_without_conditions, exclude_query)

      puts "exclude_scope before coalesce: #{exclude_scope.to_sql}"

      bind_values = exclude_scope.bind_values.map { |tuple| tuple[1] }
      exclude_scope_conditions = concatenate_where_values(exclude_scope.where_values)


      if exclude_scope_conditions.present?
        # byebug if exclude_scope.where_values.present?
        false_string = exclude_scope.connection.quoted_false
        inverted_sql = "NOT COALESCE (" + exclude_scope_conditions + ", #{false_string})"

        # puts "Bind values are #{(bind_values.inspect)}"
        # puts "Resulting scope is #{exclude_scope.except(:where).where(inverted_sql, *bind_values).to_sql}"

        # rebuilt_scope = exclude_scope.except(:where)

        exclude_scope.except(:where).where(inverted_sql, *bind_values)

        # rebuilt_scope = exclude_scope
        # rebuilt_scope = rebuilt_scope.except(:where)
        # rebuilt_scope = rebuilt_scope.where(inverted_sql)
        # rebuilt_scope.bind_values = bind_values
        # rebuilt_scope

      else
        # unknown_scoper.call(root_scope)
        warn "komisch"
        root_scope
      end
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

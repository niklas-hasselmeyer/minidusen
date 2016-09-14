# This is the DSL to describe a Syntax.
module Minidusen
  module Filter
    extend ActiveSupport::Concern

    included do

      self.minidusen_syntax = Syntax.new

    end

    class_methods do

      private

      attr_reader :minidusen_syntax

      def filter(field, &block)
        minidusen_syntax.learn_field(field, &block)
      end

    end

    def filter(scope, query)
      minidusen_syntax.search(scope, query)
    end

    private

    delegate :minidusen_syntax, to: :class

  end
end

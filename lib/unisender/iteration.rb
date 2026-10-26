# frozen_string_literal: true

module Unisender
  # Applies an optional block without changing the iterator's return type.
  module Iteration
    def self.call(items, &block)
      items.each(&block) if block
      items
    end
  end
end

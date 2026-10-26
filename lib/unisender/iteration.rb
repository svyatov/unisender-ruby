# frozen_string_literal: true

module Unisender
  # Applies an optional block without changing the iterator's return type.
  module Iteration
    def self.items(pages)
      Enumerator.new { |output| pages.each { |page| page.each { |item| output << item } } }
    end

    def self.call(items, &block)
      items.each(&block) if block
      items
    end
  end
end

# Form fields that are not model attributes (site checkboxes, choice slots).
# Resources take their values out of the params themselves; this only stops
# Avo's new-form prefill, which reads and writes every field on the record.
module Avo::FormOnlyFields
  def self.allow_prefill(record, names)
    names.each do |name|
      next if record.respond_to?(name)

      record.define_singleton_method(name) { nil }
      record.define_singleton_method(:"#{name}=") { |_value| }
    end
  end
end

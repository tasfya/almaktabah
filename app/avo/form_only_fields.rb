# Form fields that are not model attributes (site checkboxes, choice slots).
# Avo only renders a form field when the record has a writer for it, and its
# new-form prefill reads and writes every field, so the record gets inert
# accessors. Resources take the submitted values out of the params themselves.
module Avo::FormOnlyFields
  def self.define_on(record, names)
    return if record.nil?

    names.each do |name|
      next if record.respond_to?(name)

      record.define_singleton_method(name) { nil }
      record.define_singleton_method(:"#{name}=") { |_value| }
    end
  end
end

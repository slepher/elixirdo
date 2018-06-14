# Used by "mix format"
[
  locals_without_parens: [defclass: :*, deftype: :*, definstance: :*, import_typeclass: :*, import_type: :*],
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 160,
  export: [
    locals_without_parens: [defclass: :*, deftype: :*, definstance: :*, import_typeclass: :*, import_type: :*]
  ]
]

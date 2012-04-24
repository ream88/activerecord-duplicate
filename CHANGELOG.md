# 0.6.0 (April 24, 2012)

* Associations must be declared explicit as duplicatable as well, e.g. `belongs_to :posts; attr_duplicatable :text, :posts`.

* Without specifying `attr_duplicatable`, all attributes (except the primary-key) and associations will be duplicated automatically.
  This allows you to skip the `attr_duplicatable` declarations completely, if you don't have special requirements.
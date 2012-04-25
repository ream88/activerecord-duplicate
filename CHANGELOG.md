## 0.6.1 (April 25, 2012)
* `attr_duplicatable` works more like `attr_accessible`, e.g it allows multiple calls and respects whitelisted attributes from the parent STI class. Should fix #1.

## 0.6.0 (April 24, 2012)

* Associations must be declared explicit as duplicatable as well, e.g:
  ```ruby
  belongs_to :posts
  
  attr_duplicatable :text, :posts
  ```

* Without specifying `attr_duplicatable`, all attributes (except the primary-key) and associations will be duplicated automatically.
  This allows you to skip the `attr_duplicatable` declarations completely, if you don't have special requirements.
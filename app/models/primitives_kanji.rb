class PrimitivesKanji < ActiveRecord::Base
  belongs_to :primitive
  belongs_to :kanji
  set_primary_keys :primitive_id, :kanji_id
end

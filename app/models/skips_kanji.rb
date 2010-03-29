class SkipsKanji < ActiveRecord::Base
  belongs_to :skip
  belongs_to :kanji
end

class KoreansKanji < ActiveRecord::Base
  belongs_to :kanji
  belongs_to :korean
end

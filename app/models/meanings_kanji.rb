class MeaningsKanji < ActiveRecord::Base
  belongs_to :kanji
  belongs_to :meaning
end

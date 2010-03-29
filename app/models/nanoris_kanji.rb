class NanorisKanji < ActiveRecord::Base
  belongs_to :nanori
  belongs_to :kanji
end

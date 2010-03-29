class PinyinsKanji < ActiveRecord::Base
  belongs_to :pinyin
  belongs_to :kanji
end

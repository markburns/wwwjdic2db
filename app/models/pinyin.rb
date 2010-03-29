class Pinyin < ActiveRecord::Base
  belongs_to :pinyins_kanji
  has_many :kanjis, :through => :pinyins_kanji
end

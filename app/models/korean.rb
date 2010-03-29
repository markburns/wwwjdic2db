class Korean < ActiveRecord::Base
  has_many :koreans_kanji
  has_many :kanjis, :through => :koreans_kanji
end

class Dictionary < ActiveRecord::Base
	has_many :kanji_lookups
	has_many :kanjis, :through => :kanji_lookups
end

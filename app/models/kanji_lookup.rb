class KanjiLookup < ActiveRecord::Base
	belongs_to :kanji
	belongs_to :dictionary
end

class OnyomisKanji < ActiveRecord::Base
  belongs_to :onyomi
  belongs_to :kanji
  def to_s 
    onyomi.to_s + kanji.to_s
  end
end

class Kunyomi < ActiveRecord::Base
  has_many :kunyomis_kanjis
  has_many :kanjis, :through => :kunyomis_kanjis

  has_many :kanji_words, :through => :kunyomi_readings
  has_many :english_meanings, :through => {:kanji_words => :english_meanings}
  def kunyomi
    (    read_attribute :kunyomi)#.force_encoding 'utf-8'
  end
  def to_s
    kunyomi
  end

end

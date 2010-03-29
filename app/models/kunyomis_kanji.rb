class KunyomisKanji < ActiveRecord::Base
  belongs_to :kunyomi
  belongs_to :kanji
  def to_s 
    kunyomi.to_s + kanji.to_s
  end

end

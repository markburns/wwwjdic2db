class KunyomiReadings < ActiveRecord::Base
  belongs_to :kunyomi
  belongs_to :kanji_word
end

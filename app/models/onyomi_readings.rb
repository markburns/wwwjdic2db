class OnyomiReadings < ActiveRecord::Base
  belongs_to :onyomi
  belongs_to :kanji_word
end

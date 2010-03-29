class Nanori < ActiveRecord::Base
  has_many :nanoris_kanjis
  has_many :kanjis, :through => :nanoris_kanjis
end

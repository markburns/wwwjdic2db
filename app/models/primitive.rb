class Primitive < ActiveRecord::Base
  has_many :primitives_kanjis
  has_many :kanjis, :through => :primitives_kanjis









  
  belongs_to :equivalent_kanji, :class_name => "Kanji",  
    :foreign_key => "equivalent_kanji_id"
end

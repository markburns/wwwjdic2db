class Onyomi < ActiveRecord::Base
  has_many :onyomis_kanjis

  has_many :kanjis, :through => :onyomis_kanjis
  def to_s
    onyomi
  end
end

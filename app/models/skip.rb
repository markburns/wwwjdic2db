class Skip < ActiveRecord::Base
  has_many :skips_kanjis
  has_many :kanjis, :through =>  :skips_kanjis
end

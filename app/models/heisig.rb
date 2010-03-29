class Heisig < ActiveRecord::Base
  belongs_to :kanji
  has_many :heisig_keywords, :dependent => :destroy
  
  def heisig_keyword
    heisig_keywords[0]
  end

  def keyword
    unless heisig_keywords[0].nil?
      return heisig_keywords[0].keyword
    end
    return ""
  end


end

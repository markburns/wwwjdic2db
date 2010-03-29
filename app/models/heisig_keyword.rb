class HeisigKeyword < ActiveRecord::Base
  belongs_to :heisig
  has_one :heisig_edition
  has_one :language
  def kanji
    return heisig.kanji unless heisig.nil?
  end
end

require 'spec_helper'

describe Minidusen::Util do

  describe '.boolean_fulltext_query' do

    it 'should generate a query for boolean MySQL fulltext search, which includes all words and allows additional characters on the right side' do
      Minidusen::Util.boolean_fulltext_query(['aaa', 'bbb']).should == '+aaa* +bbb*'
    end

    it 'should keep phrases intact' do
      Minidusen::Util.boolean_fulltext_query(['aaa', 'bbb ccc', 'ddd']).should == '+aaa* +"bbb ccc" +ddd*'
    end

    it 'should escape characters that have special meaning in boolean MySQL fulltext searches' do
      Minidusen::Util.boolean_fulltext_query(['+-~\\']).should == '+\\+\\-\\~\\\\*'
    end

  end

  describe '#normalize_word_boundaries' do

    it 'should remove characters that MySQL would mistakenly consider a word boundary' do
      Minidusen::Util.normalize_word_boundaries("E.ON Bayern").should == 'EON Bayern'
      Minidusen::Util.normalize_word_boundaries("E.ON E.ON").should == 'EON EON'
      Minidusen::Util.normalize_word_boundaries("E;ON").should == 'EON'
      Minidusen::Util.normalize_word_boundaries("Baden-Baden").should == 'BadenBaden'
    end

    it 'should remove characters that MySQL would mistakenly consider a word boundary' do
      Minidusen::Util.normalize_word_boundaries("Foobar Raboof").should == 'Foobar Raboof'
    end

  end

end

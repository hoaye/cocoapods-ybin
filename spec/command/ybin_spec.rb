require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Ybin do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ ybin }).should.be.instance_of Command::Ybin
      end
    end
  end
end


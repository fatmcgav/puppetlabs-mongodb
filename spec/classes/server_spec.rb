require 'spec_helper'

describe 'mongodb::server' do
  let :facts do
    {
      :osfamily        => 'Debian',
      :operatingsystem => 'Debian',
    }
  end

  context 'with defaults' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('mongodb::server::install').
        that_comes_before('Class[mongodb::server::config]') }
    it { is_expected.to contain_class('mongodb::server::config').
        that_notifies('Class[mongodb::server::service]') }
    it { is_expected.to contain_class('mongodb::server::service') }
  end

  context 'with create_admin => true' do
    let(:params) do 
      {
        :create_admin   => true,
        :admin_username => 'admin',
        :admin_password => 'password'
      }
    end
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('mongodb::server::install').
        that_comes_before('Class[mongodb::server::config]') }
    it { is_expected.to contain_class('mongodb::server::config').
        that_notifies('Class[mongodb::server::service]') }
    it { is_expected.to contain_class('mongodb::server::service') }

    it {
        is_expected.to contain_mongodb_user('admin').with({
          'username' => 'admin', 
          'ensure'   => 'present',
          'database' => 'admin', 
          'roles'    => ['dbAdmin', 'dbOwner', 'userAdmin', 'userAdminAnyDatabase'],
          'tries'    => 10, 
          'tag'      => 'admin'
        })
      }
  end

  context 'when deploying on Solaris' do
    let :facts do
      { :osfamily        => 'Solaris' }
    end
    it { expect { is_expected.to raise_error(Puppet::Error) } }
  end

  context 'setting nohttpinterface' do
    it "isn't set when undef" do
      is_expected.to_not contain_file('/etc/mongodb.conf').with_content(/nohttpinterface/)
    end
    context "sets nohttpinterface to true when true" do
      let(:params) do
        { :nohttpinterface => true, }
      end
      it { is_expected.to contain_file('/etc/mongodb.conf').with_content(/nohttpinterface = true/) }
    end
    context "sets nohttpinterface to false when false" do
      let(:params) do
        { :nohttpinterface => false, }
      end
      it { is_expected.to contain_file('/etc/mongodb.conf').with_content(/nohttpinterface = false/) }
    end
    context "on >= 2.6" do
      let(:pre_condition) do
        "class { 'mongodb::globals': version => '2.6.6', }"
      end
      it "isn't set when undef" do
        is_expected.to_not contain_file('/etc/mongodb.conf').with_content(/net\.http\.enabled/)
      end
      context "sets net.http.enabled false when true" do
        let(:params) do
          { :nohttpinterface => true, }
        end
        it { is_expected.to contain_file('/etc/mongodb.conf').with_content(/net\.http\.enabled: false/) }
      end
      context "sets net.http.enabled true when false" do
        let(:params) do
          { :nohttpinterface => false, }
        end
        it { is_expected.to contain_file('/etc/mongodb.conf').with_content(/net\.http\.enabled: true/) }
      end
    end
  end
end

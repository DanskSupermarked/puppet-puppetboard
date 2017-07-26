require 'spec_helper'
describe 'puppetboard' do
  context 'with default values for all parameters' do
    let(:facts) { {:ipaddress_lo => '127.0.0.1'} }
    it { should contain_file('/etc/init.d/supervisord') }
    it { should contain_file('/etc/supervisord.d') }
    it { should contain_package('gcc') }
    it { should contain_package('gevent').with_provider('pip') }
    it { should contain_package('gunicorn').with_provider('pip') }
    it { should contain_package('puppetboard').with_provider('pip') }
    it { should contain_package('python2-pip') }
    it { should contain_package('supervisor').with_provider('pip') }
    it { should contain_service('puppetboard') }
    it { should contain_service('supervisord') }

    it { should contain_class('puppetboard::config') }

    describe 'puppetboard::config' do
      it { should contain_exec('generate_supervisor_conf') }
      it { should contain_file('/var/log/supervisor') }
    end

  end
end

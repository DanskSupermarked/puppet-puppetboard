require 'spec_helper'

describe 'puppetboard' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      
      it { is_expected.to compile.with_all_deps }

      it { should contain_file('/etc/init.d/supervisord') }
      it { should contain_file('/etc/supervisord.d') }
      it { should contain_package('gevent').with_provider('pip') }
      it { should contain_package('gunicorn').with_provider('pip') }
      it { should contain_package('puppetboard').with_provider('pip') }
      it { should contain_package('python2-pip') }
      it { should contain_package('supervisor').with_provider('pip') }
      it { should contain_group('puppetboard') }
      it { should contain_user('puppetboard') }
      it { should contain_service('puppetboard') }
      it { should contain_service('supervisord') }

      it { should contain_class('puppetboard::config') }

      case facts[:os]['release']['major']
      when '6'
        it { should contain_package('python-devel') }
        it { should contain_package('gevent').with_ensure('1.1.2') }
      else
        it { should_not contain_package('python-devel') }
        it { should contain_package('gevent').with_ensure('present') }
      end

      describe 'puppetboard::config' do
        it { should contain_exec('generate_supervisor_conf') }
        it { should contain_file('/var/log/puppetboard').with_owner('puppetboard') }
      end

    end
  end

end

# copyright: 2020, Spokey Wheeler

control 'informix-01' do
  impact 0.5
  title 'Informix directories and files'
  desc 'Check some key directories and files'
  describe file('/tmp') do
    it { should exist }
    its('type') { should cmp 'directory' }
    it { should be_sticky }
  end
  describe file('/opt/informix/.bashrc') do
    it { should exist }
    its('type') { should cmp 'file' }
  end
  describe file('/opt/informix/informix') do
    it { should exist }
    its('owner') { should cmp 'informix' }
    its('group') { should cmp 'informix' }
    it { should be_symlink }
    it { should be_linked_to '/opt/informix/14.10.FC3' }
  end
  describe file('/opt/informix/informix/etc/sqlhosts') do
    it { should exist }
    its('type') { should cmp 'file' }
    its('owner') { should cmp 'informix' }
    its('group') { should cmp 'informix' }
  end
  describe file('/opt/informix/informix/etc/onconfig') do
    it { should exist }
    its('type') { should cmp 'file' }
    its('owner') { should cmp 'informix' }
    its('group') { should cmp 'informix' }
  end
  describe filesystem('/') do
    its('size_kb') { should be >= 100 * 1024 * 1024 }
    its('percent_free') { should be >= 30 }
  end
end

control 'informix-02' do
  impact 1.0
  title 'Informix should be running'
  desc 'onstat - stdout should contain either Prim or Read-Only or RSS'
  describe command("source /opt/informix/.bashrc ; onstat - | egrep \"Prim|Read-Only|RSS\" | wc -l | awk '{print $1}'").stdout do
    it { should cmp 1 } 
  end
end

control 'informix-03' do
  impact 0.7
  title 'Use latest stable Informix version'
  desc 'onstat - stdout should be 14.10.FC3'
  describe command("source /opt/informix/.bashrc ; onstat - | grep '14.10.FC3 | wc -l | awk '{print $1}'").stdout do
    it { should cmp 1 } 
  end
end

control 'informix-04' do
  impact 0.4
  title 'Only one instance of Informix should be running'
  desc 'onstat -g dis should only return one server with an Up status'
  describe command("source /opt/informix/.bashrc ; onstat -g dis | grep \" : Up\" | wc -l | awk '{print $1}'").stdout do
    it { should cmp 1 } 
  end
end

control 'informix-05' do
  impact 0.5
  title 'Check ports'
  desc 'oninit should be listening to TCP and UDP on 9088 and 9089'

  infx_ip = command('hostname -i')

  describe port(9088) do
    it { should be_listening }
    its('processes') { should include 'oninit' }
    its('protocols') { should cmp 'tcp' }
    its('addresses') { should include infx_ip.stdout.chomp }
  end

  describe port(9089) do
    it { should be_listening }
    its('processes') { should include 'oninit' }
    its('protocols') { should cmp 'tcp' }
    its('addresses') { should include infx_ip.stdout.chomp }
  end
end

control 'informix-06' do
  impact 0.5
  title 'Check non-standard ports'
  desc 'Check oninit is not running on non-standard ports'
  # what about mongo and mq ports though?
  describe port.where { process =~ /oninit/ && port < 9088 && port > 9088 } do
    it { should_not be_listening }
  end
end

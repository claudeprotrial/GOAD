import os
import tempfile
from goad.command.cmd import Command
import subprocess
from goad.log import Log


class WindowsCommand(Command):

    def __init__(self):
        super().__init__()
        self.vagrant_bin = 'vagrant.exe'
        self.terraform_bin = 'terraform.exe'

    def file_exist(self, file):
        exist = os.path.isfile(file)
        if exist:
            Log.success(f'File {file} present in the file system')
        return exist

    def is_in_path(self, bin_file, show_log=True):
        command = f'where {bin_file} >nul'
        try:
            subprocess.run(command, shell=True, check=True)
            if show_log:
                Log.success(f'{bin_file} found in PATH')
            return True
        except subprocess.CalledProcessError as e:
            if show_log:
                Log.error(f'{bin_file} not found in PATH')
            return False

    # CHECK
    def check_gem(self, gem_name):
        # not needed
        pass

    def check_vmware(self):
        return self.file_exist("c:\\Program Files (x86)\\VMware\\VMware Workstation\\vmrun.exe")

    def check_vmware_utility(self):
        return self.file_exist("c:\\Program Files\\VagrantVMwareUtility\\vagrant-vmware-utility.exe")

    def check_ovftool(self):
        return self.file_exist("c:\\Program Files\\VMware\\VMware OVF Tool\\ovftool.exe")

    def check_virtualbox(self):
        return self.file_exist("c:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe")

    def check_terraform(self):
        return self.is_in_path('terraform.exe')

    def check_ludus(self):
        return False

    # ------------------------------------------------------------------
    # rsync replacement
    #
    # GOAD syncs its sources to the azure/aws jumpbox with rsync, which does
    # not exist on Windows (and the Git-for-Windows build would choke on
    # "C:\..." paths anyway, reading the drive letter as a remote host).
    #
    # tar + scp + remote untar is equivalent for our purposes: the jumpbox is
    # provisioned from scratch, so there is nothing to do incrementally. Each
    # step is a single command with no pipes, which keeps it robust under
    # cmd.exe (subprocess shell=True).
    # ------------------------------------------------------------------

    def check_rsync(self):
        # rsync is replaced by tar+scp on windows, only its transport is needed
        checks = [self.is_in_path('tar'), self.is_in_path('scp'), self.is_in_path('ssh')]
        if all(checks):
            Log.success('rsync not needed on windows, using tar+scp instead')
            return True
        Log.error('tar, scp and ssh are required to sync sources to the jumpbox')
        return False

    @staticmethod
    def _tar_excludes(source):
        """Translate .gitignore entries into tar --exclude patterns."""
        excludes = ['.git']
        gitignore = os.path.join(source, '.gitignore')
        if os.path.isfile(gitignore):
            with open(gitignore, 'r') as f:
                for line in f:
                    line = line.strip()
                    # comments, blanks and negations have no tar equivalent
                    if not line or line.startswith('#') or line.startswith('!'):
                        continue
                    excludes.append(line.strip('/'))
        return excludes

    def rsync(self, source, destination, ssh_key, exclude=True):
        Log.info(f'Sync (tar+scp) {source} -> {destination}')
        if ':' not in destination:
            Log.error(f'Invalid rsync destination: {destination}')
            return False
        user_host, remote_path = destination.split(':', 1)

        # rsync semantics: a trailing separator on the source means "the
        # contents of this directory", without it means "this directory".
        contents_only = source.endswith(('/', os.path.sep))
        src = source.rstrip('/' + os.path.sep)
        if contents_only:
            tar_dir, tar_target = src, '.'
        else:
            tar_dir, tar_target = os.path.dirname(src), os.path.basename(src)

        tmp_tar = os.path.join(tempfile.gettempdir(), f'goad-sync-{os.getpid()}.tar.gz')
        remote_tar = f'/tmp/goad-sync-{os.getpid()}.tar.gz'

        exclude_args = ''
        if exclude:
            for pattern in self._tar_excludes(src):
                exclude_args += f' --exclude="{pattern}"'
        else:
            exclude_args = ' --exclude=".git"'

        # --force-local: without it tar reads "C:\path" as host:path
        tar_cmd = (f'tar --force-local -czf "{tmp_tar}"{exclude_args} '
                   f'-C "{tar_dir}" "{tar_target}"')
        scp_cmd = (f'scp -o StrictHostKeyChecking=no -i "{ssh_key}" '
                   f'"{tmp_tar}" {user_host}:{remote_tar}')
        untar_cmd = (f'ssh -o StrictHostKeyChecking=no -i "{ssh_key}" {user_host} '
                     f'"mkdir -p {remote_path} && tar -xzf {remote_tar} -C {remote_path} '
                     f'&& rm -f {remote_tar}"')
        try:
            for step in (tar_cmd, scp_cmd, untar_cmd):
                if not self.run_command(step, tar_dir):
                    Log.error('Source sync to the jumpbox failed')
                    return False
        finally:
            if os.path.isfile(tmp_tar):
                os.remove(tmp_tar)
        Log.success(f'Sources synced to {destination}')
        return True

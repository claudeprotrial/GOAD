from goad.provider.provider import Provider
import os
import shutil
import sys
from goad.goadpath import GoadPath
from goad.log import Log


class TerraformProvider(Provider):

    def check(self):
        checks = [
            self.command.check_terraform(),
            self.command.check_rsync()
        ]
        return all(checks)

    @staticmethod
    def _approval_args():
        """
        Terraform asks for approval on stdin. When GOAD is driven
        non-interactively (a script, CI, or any piped stdin) that read hits
        EOF and terraform gives up with "error asking for approval: EOF",
        after the plan has already been computed.

        Feeding the answer in through the pipe does not work either: GOAD
        asks its own "Create lab with theses settings ?" first, and python's
        buffered input() consumes the following line meant for terraform.

        Set GOAD_AUTO_APPROVE=1 to approve automatically. The non-tty case
        is also covered, but that check alone is not enough: a task runner
        can hand the process an inherited tty that nobody is ever going to
        type into, and terraform then blocks or hits EOF anyway.

        The operator has already confirmed once through GOAD before
        reaching this point.
        """
        if os.environ.get('GOAD_AUTO_APPROVE', '').lower() in ('1', 'true', 'yes'):
            return ['-auto-approve']
        if sys.stdin is None or not sys.stdin.isatty():
            return ['-auto-approve']
        return []

    def install(self):
        self.command.run_terraform(['init'], self.path)
        self.command.run_terraform(['plan'], self.path)
        return self.command.run_terraform(['apply'] + self._approval_args(), self.path)

    def destroy(self):
        return self.command.run_terraform(['destroy'] + self._approval_args(), self.path)

    def start(self):
        pass

    def stop(self):
        pass

    def status(self):
        pass

    def start_vm(self, vm_name):
        pass

    def stop_vm(self, vm_name):
        pass

    def destroy_vm(self, vm_name):
        pass

    def ssh_jumpbox(self):
        pass

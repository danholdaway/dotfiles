#!/usr/bin/env python3

###############################################################
# tcluster - open/close/restart a tunnel to cluster machines
###############################################################

import sys
import os
import subprocess as sp
from shlex import split
from getpass import getuser
import click

clusters = ['discover', 'orion', 's4', 's4-submit', 'devwcoss', 'prodwcoss', 'cheyenne']


class Tunnel(object):

    def __init__(self, machine):

        self.machine = machine
        self.__checkStatus

    def __str__(self):
        pass

    def __repr__(self):
        pass

    @property
    def isOpen(self):
        status = False
        if self.__plist:
            for pid in self.__plist:
                status = True
        return status

    @property
    def __checkStatus(self):
        try:
            proc1 = sp.Popen(split('ps x'), stdout=sp.PIPE)
            proc2 = sp.Popen(split('grep -e "-YMNfq %s"' % self.machine),
                             stdin=proc1.stdout, stdout=sp.PIPE, stderr=sp.PIPE)
            proc3 = sp.Popen(split('grep -v grep'),
                             stdin=proc2.stdout, stdout=sp.PIPE, stderr=sp.PIPE)
            proc4 = sp.Popen(split('awk "{print $1}"'),
                             stdin=proc3.stdout, stdout=sp.PIPE, stderr=sp.PIPE)
            proc1.stdout.close()
            proc2.stdout.close()
            proc3.stdout.close()
            o, e = proc4.communicate()
        except:
            raise SystemExit("An exception occurred in checkStatus")

        plist = []
        if o:
            lines = o.decode().split('\n')
            if (lines[0][0:4] == 'dyld'):
                plist = lines[1:-1]
            else:
                plist = lines[:-1]

        self.__plist = plist
        return

    @property
    def create(self):
        self.__rmMasterFile
        try:
            sp.call(['ssh', '-YMNfq', f'{self.machine}'])
        except:
            raise OSError(f"tunnel to {self.machine} was not created")
        return

    @property
    def close(self):
        print(f"closing tunnel to {self.machine}")
        if self.__plist:
            for pid in self.__plist:
                try:
                    sp.call(['kill', '%s' % pid])
                except:
                    raise OSError(f"tunnel to {self.machine} could not be closed through process id {pid}")
            self.__rmMasterFile
        else:
            print(f"No tunnels open to {self.machine}")
        return

    @property
    def list(self):
        if self.__plist:
            for pid in self.__plist:
                print(
                    f"Tunnel to {self.machine} is running as process id {pid}")
        else:
            print(f"No tunnels open to {self.machine}")
        return

    @property
    def __getMasterFileName(self):
        masterFile = f"{os.environ['HOME']}/.ssh/master-{getuser()}@{self.machine}:22"
        return masterFile

    @property
    def __rmMasterFile(self):
        masterFile = self.__getMasterFileName
        if (os.path.exists(masterFile)):
            try:
                sp.call(['rm', '-f', masterFile])
            except:
                raise OSError(f"Failed to remove master file {masterFile} for machine {self.machine}")
        return


@click.command()
@click.option('--machine', '-m', required=True, type=click.Choice(clusters))
@click.option('--list', '-l', 'list_', required=False, is_flag=True, show_default=True, help='list open tunnels')
@click.option('--restart', '-r', required=False, is_flag=True, show_default=True, help='restart open tunnels')
@click.option('--kill', '-k', required=False, is_flag=True, show_default=True, help='close open tunnels')
@click.option('--clean', '-c', required=False, is_flag=True, show_default=True, help='close and clean open tunnels')
def main(machine, list_, restart, kill, clean):

    tmachine = Tunnel(machine)

    if list_:
        tmachine.list

    if kill or clean or restart:
        tmachine.close

    if list_ or kill or clean:
        return

    if tmachine.isOpen:
        raise SystemExit(f"Tunnel to {machine} is already open, use it!")

    tmachine.create
    tmachine.list

    return

if __name__ == "__main__":
    main()

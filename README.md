
## Mac-centric instructions for using an Integrated Development Environment (IDE) such as VSCode on an HPC platform that allows tunneling.

Running an IDE over SSH is not likely to provide a satisfactory user experience due to cross network lag. Instead the files of the projects you wish to work on need to be mounted on your local machine so the software can run locally.

*Always practice good IT security, for example using a VPN.*

### Required software

1. An IDE such as Visual Studio Code.
2. Python. This is likely most easily achieved using Miniconda.
3. For mounting drives you need SSHFS (From Self Service) and MacFuse [https://osxfuse.github.io/](https://osxfuse.github.io/ "https://osxfuse.github.io/") . This requires admin privilege on your machine. Later when you try to use MacFuse you might have to go in system preferences and 'trust the software developer' (requires restart).

### Establishing a tunnel

 Clone this repo to e.g. your `$HOME` directory:
 ``` zsh 
 cd $HOME
 git clone https://github.com/danholdaway/dotfiles
 ```

Copy the file `bin/tunnel_cluster.py` to your own `$HOME/bin` directory and make sure that `$HOME/bin` is in your path. In `zsh` this can be done with `export PATH=$HOME/bin:$PATH`.  Note that this repo contains a `zshenv` file with examples.

This Python script is useful for managing your tunnels, it allows you to create a tunnel to a specific platform, check on existing tunnels, and remove tunnels.

Before you can establish a tunnel to your favorite HPC machine you need to put the appropriate directives into your `$HOME/.ssh/config` file. There is an example of this file in the repo. The lines that are needed are, e.g.,:

``` zsh
Host {{machine}}
    ProxyCommand ssh host-PIV direct {{machine}}.{{host}}
    User {{user}}

Host host-PIV
    HostName login.{{host}}
    PKCS11Provider /usr/lib/ssh-keychain.dylib
 
Host *
    ControlPath ~/.ssh/master-%r@%h:%p
    ControlMaster no
    LogLevel Quiet
    Protocol 2
    ServerAliveInterval 900
```

Note that terms in double curly braces `{{}}` are to be replaces with the actual information for the machine being accessed. Note also that the above is needed when there is a gateway to the machine. For example you login to that gateway then make the selection of the machine you want. If not gateway exists then only then `direct` can be omitted. 

Now you are ready to try and create a tunnel. Place directives, similar to the following, into you `$HOME/.zshenv` or equivalent file:

``` zsh
alias  {{machine}}='ssh -XY {{machine}}'
alias  ctunnel{{machine}}='python3 $HOME/bin/tunnel_cluster.py -m {{machine}}'
alias  ktunnel{{machine}}='python3 $HOME/bin/tunnel_cluster.py -m {{machine}} -k'
alias  ltunnel{{machine}}='python3 $HOME/bin/tunnel_cluster.py -m {{machine}} -l'
```

Note that these are shortcuts providing access to the `tunnel_cluster` code that you put in the bin directory.

Try to create a tunnel to {{machine}} using `ctunnel{{machine}}`. To check that the tunnel is active open a new tab or window of the Terminal and simply type `{{machine}}`. This should open another connection without prompting you for a password.

### Mounting a project or drive

Once you have MacFuse installed you can try to mount a drive using your newly established tunnel. Add the following shortcuts to `$HOME/.zshenv`:

``` zsh
alias  mountremotedrive='sshfs {{machine}}:/{{remote_path}}/ $HOME/Volumes/remotedrive'
alias  umountremotedrive='diskutil unmountDisk force $HOME/Volumes/remotedrive'
```

Now create a directory where the mount will appear:

``` zsh
mkdir -p $HOME/Volumes/remotedrive
```

Try to mount the drive with `mountremotedrive`.

Now you should be ready to connect your IDE to your entire drive or projects that live on that drive.

### Tips

1. When your connection fails it can cause trouble for the mounted drive and your IDE that is accessing those files. As such you should not kill your tunnel 
2. If experiencing lag you can try turning off communication with GitHub by the IDE. It might be trying to read a lot of files on the mounted drive.

# Using an Integrated Development Environment (IDE) such as VSCode on Hera.

### Step 1: Identify Local Port on Hera

Log into Hera as you normally would. You will see something like:

```bash
You will now be connected to OneNOAA RDHPCS: Hera (NESCC) system.
To select a specific host, hit ^C within 5 seconds.
Local port 65445 forwarded to remote host.
Remote port 11910 forwarded to local host.
```

Note down the Local Port. In this case 65445, but different for everyone.

### Step 2: Put Hera Entries in you ssh config

On you personal machine add the following to your $HOME/.ssh/config

``` bash
# NOAA Hera
# ---------
Host heraPrinceton hera
  User <First.Last>
  HostName hera-rsa.princeton.rdhpcs.noaa.gov

Host heraBoulder
  User <First.Last>
  HostName hera-rsa.rdhpcs.noaa.gov

Host heraLocal
  User <First.Last>
  HostName localhost
  Port <LocalPort>
```

Replacing `<First.Last>` with your actual Hera username and `<LocalPort>` with the port number identified in the first step. If you prefer the Boulder bastion then change `Host heraPrinceton hera` to just `Host heraPrinceton` and `Host heraBoulder` to `Host heraBoulder hera`. This aliases `hera` to your preferred Bastion.

### Step 3: Add aliases to profile.

On you local machine add the following conveniences to your profile, `$HOME/.bash_profile` (Linux) or `$HOME/.zshenv` (Mac).

```bash
# NOAA Hera
# ---------
grep -v '\[localhost\]:<LocalPort>' $HOME/.ssh/known_hosts > $HOME/.ssh/known_hosts_nolh
mv $HOME/.ssh/known_hosts_nolh $HOME/.ssh/known_hosts

alias hera='ssh -vXYq heraLocal'
alias ctunnelhera='ssh -XYqL 65445:localhost:65445 hera'
alias ctunnelheraBoulder='ssh -XYqL 65445:localhost:65445 heraBoulder'
```

Explanation: The first three lines remove localhost from the remembered server list each time you login. This prevents an silent error that can occur when you have the Hera local host remembered in the list.

The other lines are just shortcuts. The last line is used when the Princeton bastion is unusable for some reason. If you prefer the Boulder bastion you can remove `Boulder` from the first and change the other to `ctunnelheraPrinceton`.

### Step 4: Allow for password-less ssh between your local machine and Hera.

A benefit of having a tunnel is that you can login once and then open many windows or tabs to the machine in each session. But to make use of this you need password-less SSH.

On your local machine you run:

```bash
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
```

to generate a private key and display it in the terminal.

Now log into Hera and append `$HOME/.ssh/authorized_keys` with the key you generated on your local machine.

### Step 5: Check that you can open a tunnel and not enter your password.

Run the command `ctunnelhera`. You will have to enter your pin / password combination to login. Leaving that window alone open another window and type `hera`. You should now have another window to Hera and have logged in without needing a password. If you are asked for a password go back and check previous steps.

Note: The original window where you typed `ctunnelhera` serves to keep the tunnel open. If you close this window you will close the tunnel and sever all other connections.

### Step 6: Setup your IDE

Now you can try an IDE. Download and install the latest version of VSCode. In the market place of VSCode search for the `Remote - SSH` extension from Microsoft and install it.

In the lower left corner of VSCode click the green box with two arrows to open a remote window. At the top click `Connect to Host` and then select heraLocal. It might take a few seconds first time while some VSCode hooks are installed on Hera but after that you will be able to browse your files on Hera and start benefiting from the vast resources that VSCode enables. You can have language helpers from the marketplace, have a terminal in the window, use Jupyter notebooks, markdown previews and if change is scary even have Emacs key bindings ;)!

# Mac-centric instructions for using an Integrated Development Environment (IDE) such as VSCode on an HPC platform like Orion

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

Note that terms in double curly braces `{{}}` are to be replaced with the actual information for the machine being accessed. Note also that the above is needed when there is a gateway to the machine. For example you login to that gateway then make the selection of the machine you want. If no gateway exists then `direct` can be omitted.

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

1. When your connection fails it can cause trouble for the mounted drive and your IDE that is accessing those files. As such you should not kill your tunnel before unmounting the drive.
2. If experiencing lag you can try turning off communication with GitHub by the IDE. It might be trying to read a lot of files on the mounted drive.

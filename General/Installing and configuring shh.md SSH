Installing SSH (Ubuntu server proxmox runs on debian? so its all different)
	sudo apt update
	sudo apt install openssh-server -y	#Installs openssh server
	sudo systemctl start ssh && sudo systemctl enable ssh && sudo systemctl status ssh #Start ssh and enable it to start at boot and check status
	
Adding a banner file for the ssh conf to use:
	sudo nano /etc/ssh/ssh_banner


	
****************************************************************
* WARNING: Authorized users only. All activity is logged.      *
****************************************************************



Save and exit.

Settings to change in /etc/ssh/sshd_config
	Blocking root user from connecting with ssh
		sudo nano /etc/ssh/sshd_config
		uncomment #PermitRootLogin prohibit-password
	Enable last log when logging in
		Uncomment #PrintLastLog yes
	Enable banner:
		Uncomment #Banner none and add the path /etc/ssh/ssh_banner
		
After adding changes restart ssh server
	sudo systemctl restart ssh







Setup key authentication	#We want this because its more secure then just a password

#On the connecting device:
	Windows: 
		make folders
		ssh-keygen -t ed25519 -C "$hostname-target" -f C:\Users\$username_connecting_device\.ssh\$hostname_target\$hostname_target #Makes keys
	Linux:
		mkdir -p "$HOME/.ssh/$hostname_target"
		ssh-keygen -t ed25519 -C "$hostname_target" -f "$HOME/.ssh/$hostname_target/$hostname_target"
		
# To make ssh easier otherwise you would have to login with this ssh -i ~/.ssh/$target-hostname/$target-hostname $target-username@$target-IP
	Windows:
	go the the C:\Users\$username\.ssh dir
	make a file called config (if it doesnt exist) and add the following template per target machine
	
Host $target-hostname
	HostName XXX.XXX.XXX.XXX
	User $username-target-machine
	IdentityFile C:\Users\$username\.ssh\$target-hostname\$target-hostname
	
	Linux:
	Go to ~/.ssh/
		cd ~/.ssh/
	Make config file if it doesnt exist other wise open it and add the following template per target machine
		sudo nano config
	
Host $target-hostname
	HostName XXX.XXX.XXX.XXX
	User $username-target-machine
	IdentityFile ~/.ssh/$target-hostname/$target-hostname

	
#This is all on the target device
Copy the public key to the VM:
	sudo nano ~/.ssh/authorized_keys
	and add	1 key per line
	
enable and load the authorized_keys file
	sudo nano /etc/ssh/sshd_config
	Uncomment #PubkeyAuthentication yes
	Change #AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2 to AuthorizedKeysFile .ssh/authorized_keys
	
Disable password login for all users
	Uncomment #PasswordAuthentication and set value to no
	Uncomment #KbdInteractiveAuthentication no #most likely already the default but check
	
Restart SSH
	sudo systemctl restart ssh




Installing and configuring fail2ban

Install fail2ban
	sudo apt install fail2ban -y
configuring to start and to start automatically
	sudo systemctl enable fail2ban && sudo systemctl start fail2ban && sudo systemctl status fail2ban #Start Fail2Ban and enable it to start at boot and check status
Make a copy of the default jail
	sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
configure the jail
	sudo nano /etc/fail2ban/jail.local
	
# Default ssh jail
[sshd]

# To use more aggressive sshd modes set filter parameter "mode" in jail.local:
# normal (default), ddos, extra or aggressive (combines all).
# See "tests/files/logs/sshd" or "filter.d/sshd.conf" for usage example and details.
#mode   = normal
port    = ssh	#put custom port here if applicable if not put ssh or 22 here
filter  = sshd	#Refers to the filter file /etc/fail2ban/filter.d/sshd.conf, This defines regex patterns to detect failed login attempts in log files.
logpath = /var/log/fail2ban/auth.log #Path to the log file that Fail2Ban reads to detect failures.
backend = %(sshd_backend)s #Defines the log reading method.
maxretry = 3 #Number of failed attempts allowed before banning the IP.
bantime = 1h #How long a banned IP is blocked.
findtime = 10m #The time window for counting failed attempts.
	
# Make sure the log file location exist and that there is an empty file
	sudo mkdir /var/log/fail2ban
	sudo touch /var/log/fail2ban/auth.log

restart fail2ban to apply changes
	sudo systemctl restart fail2ban && sudo systemctl status fail2ban




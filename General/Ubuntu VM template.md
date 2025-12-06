1. 	Create VM
2.	General:
		VM ID: 
		Name: 
	OS:
		ISO image: Ubuntu Server
		Type: Linux	
	System:
		GPU: Default unless otherwise
		Machine: q35
		Bios: SeaBIOS
		SCSI Controller: VirtIO SCSI single
	Disk:
		Disk size: fill in what is needed
		Cashe: Write through
		Discard: Checked
	CPU:
		Sockets: fill in what is needed
		Cores: fill in what is needed
		Type: host
	Memory:
		Memory: fill in what is needed
		
	Network:
			Leave as is
			

Proxmox settings changes:
	Options:
 		Start at boot: Yes
		Start/Shutdown order: next one up 	#Startup is in acending order and shutdown in decending order 
		Startup delay: 						#Waits x second before starting the next vm in the order
		Shutdown timeout: if needed 		#Waits X seconds after shutdown command to force shutdown VM
		
Install Ubuntu server
	Language: English
	Keyboard layout default
	Base for installation: Ubuntu Server
	Network configuration: default #Leave as is changing never works fix later
	Proxy configuration: blank
	Ubuntu archive mirror configuration: default
	Guided storage configuration: default #Add drives later
	Storage configuration: default
	confirm destroying of data
	Profile configuration:
		Name: $username-full-name
		Your Server name: atlantis
		Pick a username: $username
		Choose a password: $password
		Confirm your password: $password
	Upgrade to Ubuntu Pro: skip for now
	SSH configuration: unchecked we do this later
	Featured server apps: all unchecked
	Wait for install to finsh and reboot
	In proxmox stop the VM and remove the CD and start VM again

After installation:	
	Make folders:
		/drives #for all mounted drives
		/docker #for all docker related stuff
		/docker/composefiles #for compose.yaml files
		
	Disable root for local login
		sudo passwd -S root #Check if root is locked "root L" means locked "root P" means not
		sudo passwd -l root	#Locks the root account if its not locked already
			
	Update VM
		sudo apt update && apt upgrade -y	#Search for updates and install them
		sudo apt clean && sudo apt autoremove && sudo apt autoclean	#Removes old and unnecessary files
		reboot now
		
	Set static IP:
		check what interface we want to set
			ip a
		edit netplan
			sudo nano /etc/netplan/50-cloud-init.yaml

network:
  version: 2
  ethernets:
    enp6s18:
      dhcp4: no
      addresses: [XXX.XXX.XXX.XXX/24] # Static IP
      routes:
        - to: default
          via: $modem-ip #modem
      nameservers:
        addresses: [$prometheus-ip, 1.1.1.1]
		
	apply the new network settings (and pray that you did it right)
		sudo netplan apply
		
Configure ssh and Fail2Ban


# Block all ssh acces to server accept from midway-station
Ubuntu Firewall configuration, see firewall rules sudo ufw status verbose
	sudo ufw allow from $midway-station-ip to any port 22	# explicitly only lets you ssh from midway-station
	sudo ufw deny 22/tcp                             		# block all other SSH connections
	sudo ufw enable                                  		# activate the firewall
	sudo ufw status verbose									# check firewall rules

OpenSSH configuration
	sudo nano /etc/ssh/sshd_config
		# Allowed users
		AllowUsers $username-current-machine@$midway-station-ip  # only user $username-current-machine can connect from midway-station
	sudo systemctl restart ssh

Fail2Ban configuration
	sudo nano /etc/fail2ban/jail.local
		
[DEFAULT]
ignoreip = 127.0.0.1/8 $midway-station-ip # Doesnt jail local IP and midway-station

Restart fail2ban
	sudo systemctl restart fail2ban && sudo systemctl status fail2ban

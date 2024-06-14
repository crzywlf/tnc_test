resource "aws_instance" "tnc_test" {
    ami = "ami-038fd14fad41c426f"
    instance_type = "${var.EC2instanceSize}"
    vpc_security_group_ids = ["${var.SGids}"]
    subnet_id = "${var.subnetB}"
    key_name = "TerraFormTest"
    tags = { 
        Name = "${var.prefix}Test" 
    }
    provisioner "local-exec" {
        command = "echo The server's IP address is ${self.private_ip}"
    }
    
    
    provisioner "remote-exec" {
        inline = [
            "sudo su <<EOF",
            "yum install wget -y",
            "sed -i '/^GRUB_CMDLINE_LINUX=/ s/$/ transparent_hugepage=never/' /etc/default/grub",
            "grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg",
            "parted /dev/xvdb --script mklabel gpt mkpart xfspart xfs 0% 100%",
            "mkfs.xfs /dev/xvdb1",
            "partprobe /dev/xvdb1",
            "mkdir /data",
            "mount /dev/xvdb1 /data",
            "groupadd splunk",
            "useradd -d /data/splunk -m -g splunk splunk",
            "cd /data",
            "wget -O ${var.splunkversion} 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.4&product=splunk&filename=${var.splunkversion}&wget=true'",
            "tar -xvzf ${var.splunkversion} -C /data",
            "chown -R splunk:splunk /data/splunk/",
            "su splunk",
            "/data/splunk/bin/splunk start --accept-license --no-prompt --answer-yes",
            "/data/splunk/bin/splunk enable boot-start -user splunk",
            "/data/splunk/bin/splunk start -user splunk",
            "EOF",
            
        
            ]
        connection {
            type = "ssh"
            user = "ec2-user"
            private_key = file(var.pemfile)
            host = self.private_ip
            script_path = "/home/ec2-user/script.sh"
        }
    }
}

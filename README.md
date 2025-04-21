# Strapi Application Tasks
## ✅ Task 1: Setting Up a Fresh Strapi Application

### 🔧 Steps Performed:

1. **Created a New Strapi Project:**
   I used the official Strapi CLI to quickly set up a new Strapi app with default configurations. The following command was used:

   ```bash
   npx create-strapi-app my-strapi-app --quickstart
2. **Navigated Into the Project Directory: After creating the Strapi app, I moved to the project directory by running:**

bash
Copy
Edit
cd my-strapi-app
3. **Started the Development Server Using Yarn: Since Strapi is a modern Node.js app, I used Yarn to run the app. The development server was started using:**

bash
Copy
Edit
yarn develop
4. **Accessed the Working Strapi App:** Once the server was up, I accessed the app on http://localhost:1337. I then registered a new admin account to manage the content.

5. **Logged Into the Admin Panel:** After registering the admin account, I logged into the Strapi admin panel to verify everything was set up correctly.

6. **Created a New Content Type Named "Product":** Inside the Strapi admin panel, I created a new content type called "Product" to manage product entries.

7. **Added a Sample Product Entry:** I added a sample product to verify that the content creation functionality was working as expected.

**🚧 Challenges Faced & Solutions:**
Issue with Cloning Existing Repo:

Problem: I initially tried cloning the Strapi repo from GitHub but faced issues when running yarn develop because the package.json was missing the necessary script.

Solution: I abandoned the cloned repo and created a fresh Strapi app using the CLI to ensure all configurations and scripts were correct.

Admin Panel UI Issue:

Problem: After setting up the app, the login screen of the admin panel didn’t render properly.

Solution: I performed a hard refresh (Ctrl + Shift + R) on the browser, which resolved the issue and allowed me to log in successfully.

**📎 Documentation Links:**
Pull Request: PR Link

Loom Video: Video Link https://www.loom.com/share/edbc76f630c6451388243ca71ab09af3?sid=a118a8bb-a904-4182-a3df-a7e0dd1096cb

## ✅ Task 2: Add Terraform Scripts for Provisioning EC2 on Strapi Server Through Automation
# For this task, I created Terraform scripts to automate the provisioning of an EC2 instance to host the Strapi server. Here's a breakdown of what was done:

 1.**Created the Terraform Files:** I wrote Terraform scripts that include the necessary configurations for provisioning an EC2 instance. These scripts allow automation and make it easier to manage the infrastructure for Strapi hosting.

main.tf: Contains the main configuration for creating the EC2 instance.

variables.tf: Used to define the variables for instance size, region, etc.

outputs.tf: Used to output the necessary information like the public IP of the EC2 instance.

Provisioned EC2 Instance: The Terraform scripts use AWS EC2 as the infrastructure to host the Strapi application. The script automates the process of launching the instance and setting it up to run Strapi.

2. **The steps in the script will automatically:**

Create an EC2 instance with the required specifications.

Set up security groups to allow necessary traffic (e.g., port 80, 443, 1337 for web access).

Install necessary dependencies (like Node.js, Yarn) on the EC2 instance.

Automated Deployment: Once the EC2 instance is provisioned, the Strapi app will be deployed to the instance using automation, making the process faster and repeatable.

### 🚧 Challenges Faced & Solutions:

1. **Issue with EC2 Instance Connectivity:**
   - **Problem:** Initially, after provisioning the EC2 instance using Terraform, I couldn’t access the instance via SSH. The security group settings didn’t allow inbound SSH traffic.
   - **Solution:** I updated the security group configuration in the Terraform script to allow SSH traffic on port 22 from my IP. I then re-applied the Terraform plan to update the security group.

2. **Problem with Strapi Installation on EC2:**
   - **Problem:** After the EC2 instance was provisioned, I faced issues with installing Strapi on the instance. The dependencies (like Node.js and Yarn) weren’t installed correctly.
   - **Solution:** I modified the Terraform scripts to install Node.js, Yarn, and other necessary dependencies during the EC2 instance provisioning process. I used a `user_data` script in Terraform to automate the installation of required dependencies when the instance was first created.

3. **EC2 Instance Public IP Changes:**
   - **Problem:** Each time the EC2 instance was stopped and started, its public IP address changed. This made it difficult to access Strapi after restarting the server.
   - **Solution:** To address this, I assigned an Elastic IP (EIP) to the EC2 instance, ensuring that the public IP remains static and can be used to access the Strapi application consistently.

4. **Strapi Server Not Starting Automatically:**
   - **Problem:** After deploying the Strapi application on the EC2 instance, I found that the server wasn’t starting automatically after a reboot.
   - **Solution:** I configured a systemd service on the EC2 instance that ensures Strapi starts up automatically upon system reboot. This was done by creating a systemd service file and adding it to the init.d process.
  
  **Output Loom Video Link:**
  https://www.loom.com/share/bf94311b3c994a2987d352ae834c2a13

## ✅ Task 3: Automating Strapi Deployment on Dockerized EC2 Using Terraform
#For this task, I extended the existing Terraform setup to automatically deploy a Dockerized Strapi application on an EC2 instance. The goal was to provision the infrastructure and run the Strapi container without any manual SSH access.

🛠️ Work Done:
1. **Updated Terraform Scripts for Dockerized Deployment:**
Enhanced the existing Terraform setup by adding user_data in main.tf to:

Install Docker and Docker Compose.

Pull the Docker image of the Strapi app from Docker Hub:
📦 gudurubharatkumar/strapi-app:latest

Run the container automatically on instance boot with port mapping 1337:1337.

hcl
Copy
Edit
user_data = <<-EOF
  #!/bin/bash
  apt update -y
  apt install -y docker.io
  systemctl start docker
  systemctl enable docker
  docker pull gudurubharatkumar/strapi-app:latest
  docker run -d -p 1337:1337 gudurubharatkumar/strapi-app:latest
EOF
2. **No Manual Intervention Required:**
The entire deployment — from EC2 provisioning to running the Dockerized Strapi app — is handled via Terraform.

After applying terraform apply, the EC2 instance was created and the Strapi app started automatically inside a Docker container.

3. **Security Group Configurations:**
Ensured the security group (configured via Terraform) allows inbound traffic on:

Port 22 (optional for SSH)

Port 1337 (for public access to Strapi app)

4. **Strapi Successfully Deployed & Accessible:**
The Strapi admin panel was accessible via:
🌐 http://<public-ip>:1337/admin
Example: http://18.207.153.179:1337/admin

🚧 **Challenges Faced & Solutions:**
⚠️ Docker Not Installed Properly
Problem: Initial runs failed because Docker wasn’t installed before running the container.

Solution: Added step-by-step Docker installation and service enablement in the user_data block.

⚠️ **Strapi Not Binding to Public IP**
Problem: App was not accessible externally as it was bound to localhost.

Solution: Ensured the Docker image was built with Strapi config set to bind to 0.0.0.0 for public access.

⚠️ **Delayed Start on EC2 Boot**
Problem: Strapi container took time to start, causing confusion on initial access.

Solution: Verified container logs and confirmed successful startup after ~10 seconds.

📽️ Output Loom Video Link:
(https://www.loom.com/share/33cd6d3ef5fd45babe37a2ebfd856a7a?sid=d2e9c9d1-f044-4740-9373-02fb9597d467)

## Task 4 : ✅ Strapi Deployment Update Task 4🚀
Hey team! 👋
I’ve successfully completed the Strapi deployment task using Terraform, Docker, and GitHub Actions 🔧✨


# 📽️ Here’s a quick Loom walkthrough of the setup:

👉 https://www.loom.com/share/80da33cecc6e4a95a96e74d84278b238?sid=1cea80db-fbba-4edf-a345-79841cb4a465
📂 You can check out the My Github PR with all the code and configurations here:
🔗 https://github.com/BharatKumarG/strapi-deployment-automation
Let me know your thoughts or feedback. Happy to improve! 🙌

## Task 5 ✅ Successfully Deployed a Strapi CMS Application on AWS using ECS Fargate – fully managed through Terraform 💻🌩️
 
# 🔧 Project Highlights:
🐳 Containerized the Strapi application using Docker
📦 Pushed the Docker image to Amazon ECR
📜 Infrastructure-as-Code (IaC) with Terraform to:
🌐 Provision VPC, public/private subnets, Internet Gateway, and route tables
⚙️ Create an ECS Cluster and define ECS Task Definition using the Docker image
🚀 Launch an ECS Fargate Service
🔐 Configure Security Groups
📶 Set up an Application Load Balancer (ALB) to route traffic
🌍 Output the public URL of the ALB to access the Strapi app from the internet
🧪 Tested and verified successful deployment – Strapi CMS is running and accessible via the ALB URL!
 
 Loom Video : https://www.loom.com/share/a9257e19bc8942679b21eb66df3a091a?sid=ada4e291-cb50-4e59-850a-6ce3a8496119
 
 Github URL Link : https://github.com/BharatKumarG/strapi-deployment-automation 





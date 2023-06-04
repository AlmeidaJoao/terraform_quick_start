
### About the project
Welcome to our Terraform project, an excellent starting point for anyone interested in learning Terraform or exploring its capabilities. This project is designed to help you create the necessary infrastructure components and deploy a Tetris game, sourced from Docker Hub.
The image below provides a comprehensive overview of the project:
    [IMAGE]
With Terraform, you can easily provision and manage your infrastructure as code, enabling you to automate the deployment and configuration of various resources. By following this project, you'll gain hands-on experience in deploying a Tetris game using Terraform.

#### Built with ⚒️
[![Next][Next.js]][Next-url] - IaC tool used to provision all resources. 

#### Getting Started 🫣
This is an example of how you may give instructions on setting up your project locally. To get a local copy up and running follow these simple example steps.

### Prerequisites
Below are some stuff you need to ensure before running the project:
* AWS CLI
* A configured AWS profile 
* Terraform

#### Installation
1. Edit the `profile`, `shared_credentials_files`, `shared_config_files` on the `main.tf` file arguments to reflect your own settings.
2. Initialize the terraform project. In your terminal, navigate to the project directory and run the `terraform init` command. This command initializes the project and downloads any necessary providers or modules specified in the configuration files.
3. Review and validate the plan: Execute `terraform plan` to generate a plan of the actions Terraform will take. Review the output carefully to ensure it aligns with your expectations. This step helps prevent any unintended changes before applying the configuration.
4. Apply the configuration: If the plan looks good, run `terraform apply -auto-approve` to execute the configuration. The `-auto-approve` will skip interactive approval of plan before applying.
5. Congratulations! 🎉🎊 You have successfully deployed the Tetris game using Terraform. You can now access the game through the provided endpoint or URL. Enjoy playing! 
It was defined to output the URL of the load balancer on the terminal. 
       
            Apply complete! Resources: 28 added, 0 changed, 0 destroyed.

            Outputs:

            load_balancer_dns =   "tf-lb-*******.us-east-1.elb.amazonaws.com"
     
 ### To do list ✅
 This project is currently in `progress`, this is the list of features we plan to include:
 - [ ] Create Module for EC2 Instances
 - [ ] Add AutoScalling feature
 - [ ] Improve outgoing routing rule 

### Contributing 🤝
Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.
If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement". Don't forget to give the project a star! Thanks again!

    Fork the Project
    Create your Feature Branch (git checkout -b feature/AmazingFeature)
    Commit your Changes (git commit -m 'Add some AmazingFeature')
    Push to the Branch (git push origin feature/AmazingFeature)
    Open a Pull Request

### License 🪪
Distributed under the MIT License. 
  
### Authors 🤼
* **Almeida João** - *Initial work* - [AlmeidaJoao](https://github.com/AlmeidaJoao) 
* **France Simão** - *Initial work* - [FranceJoker](https://github.com/FranceJoker)

> **Warning**
> Don't forget to terminate your resources.
> If you don't want to be charged after using the resources, use the `terraform destroy` to terminate all the resources and avoid future charges. 
    
[Next.js]: https://www.terraform.io/favicon.ico
[Next-url]: https://www.terraform.io/

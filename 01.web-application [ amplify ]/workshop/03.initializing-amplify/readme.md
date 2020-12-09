# 03. INITIALIZING AMPLIFY

## LAB PURPOSE

Initialize AWS Amplify CLI that makes it easy for us to add cloud capabilities to web and mobile apps

## DEFINITIONS
----
### AMPLIFY

AWS Amplify is a set of tools and services that can be used together or on their own, to help front-end web and mobile developers build scalable full stack applications, powered by AWS. With Amplify, you can configure app backends and connect your app in minutes, deploy static web apps in a few clicks, and easily manage app content outside the AWS console.

## STEPS

### AMPLIFY

1. Open new terminal

2. Go to **library** directory 

3. Run ```amplify init```

4. Press Enter to accept the default project name **library**

5. Enter **dev** for the environment name

6. Select **None** for the default editor (we’re using Cloud9)

7. Choose **JavaScript** and **React** when prompted

8. Leave default value for **Source Directory Path** 

9. Leave default value for **Distribution Directory Path** 

10. Leave default value for **Build Command** and **Start Command**

11. Wait a while, AWS will ask about **Setup new user**, chose **Y** on this line

12. Press **Enter to continue**

13. Specify the AWS Region to **eu-west-1**

14. Leave default value for **user-name**

15. Complete the user creation using the AWS console to do so open the link which you see in the browser. 

15. Click **Next:Permissions**

16. Click **Next Tags**

16. Click **Next Review**

17. Click **Create User**

18. Download **.csv** file and go back to **Cloud9**

19. Press **Enter** to continue

20. Enter the access key of the newly created user from the **.csv** file

21. Leave **Profile name** as default

22. Chose **Y** for the question:Do you want to use an AWS profile

23. Please choose default profile you want to use

24. Press Enter

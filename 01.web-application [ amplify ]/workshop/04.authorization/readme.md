# 04. AUTHORIZATION

## LAB PURPOSE

Create User Directory

## DEFINITIONS
----
### Amazon Cognito

Amazon Cognito lets you add user sign-up, sign-in, and access control to your web and mobile apps quickly and easily. We just made a User Pool, which is a secure user directory that will let our users sign in with the username and password pair they create during registration. Amazon Cognito (and the Amplify CLI) also supports configuring sign-in with social identity providers, such as Facebook, Google, and Amazon, and enterprise identity providers via SAML 2.0

## STEPS

### AUTHORIZATION

1. Be sure to be in **library** directory 

2. Run ```amplify add auth``` to add authentication to the app

3. Select **Default Configuration** when asked: Do you want to use the default authentication and security configuration

4. **Select Username** when asked: How do you want users to be able to sign in

5. Select **No, I am done**

7. Run ```amplify push``` to create these changes in the cloud

8. Confirm that you want to continue, and wait it may take a few minutes.

9. Go to **AWS console** and verify new created resource in **AWS Cognito** service

10. Let's modify FE application, to do so add the **aws-amplify** and **aws-amplify-react** modules to our app by typing 

```bash
npm install --save aws-amplify@3.0.7 aws-amplify-react@3.1.9
```

11. Replace **src/App.js** with file **App.js** which is saved in **source** directory

12. Wait a while, for end of the process of compiling the files

13. Preview once again the running application

### CREATE AN ACCOUNT

1. Create an account in the app’s web interface by providing a username, password, and a valid email address (to receive a confirmation code at).

2. Check your email. You should have received a confirmation code message. Copy and paste the confirmation code into your app and you should then be able to log in with the username and password you entered during sign up.

3. Once you sign in, the form disappears and you can see our App component rendered below a header bar that contains your username and a ‘Sign Out’ button.


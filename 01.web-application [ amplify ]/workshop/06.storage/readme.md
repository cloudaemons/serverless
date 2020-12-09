# 06. STORAGE

## LAB PURPOSE

Build storage for hosting images

## DEFINITIONS
----
### AWS S3

Amazon Simple Storage Service (Amazon S3) is an object storage service that offers industry-leading scalability, data availability, security, and performance. This means customers of all sizes and industries can use it to store and protect any amount of data for a range of use cases, such as data lakes, websites, mobile applications, backup and restore, archive, enterprise applications, IoT devices, and big data analytics. Amazon S3 provides easy-to-use management features so you can organize your data and configure finely-tuned access controls to meet your specific business, organizational, and compliance requirements. 

## STEPS

### AUTHENTICATION

1. Be sure to be in **library** directory 

2. Run ```amplify add storage``` to add storage

3. Select **Content** at the prompt

4. Accept defaults for the **Please provide a friendly name for your resource that will be used to label this category in the project** and **Please provide bucket name**

5. Choose Auth users only when asked who should have access. Configure it so that authenticated users have access with **create/update, read, and delete access**  (use the spacebar to toggle on/off, the arrow keys to move, and Enter to continue).

6. Select **No** when asked to add a Lambda Trigger for your S3 Bucket and select Create new function. 

7. Run amplify push

8. Press Enter to confirm the changes

9. Go to **AWS Console** and verify if **S3 Bucket**

### UPDATE THE APP

1. From the albums directory, run ```npm install --save uuid @aws-amplify/storage```

2. Replace **src/App.js** with file **App.js** which is saved in **source** directory

3. Check out the app now and upload the image to the album

4. Verify if the image is successfully uploaded
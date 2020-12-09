# 07. HOSTING

## LAB PURPOSE

Deploy APP to S3

## DEFINITIONS
----
### AWS S3

Amazon Simple Storage Service (Amazon S3) is an object storage service that offers industry-leading scalability, data availability, security, and performance. This means customers of all sizes and industries can use it to store and protect any amount of data for a range of use cases, such as data lakes, websites, mobile applications, backup and restore, archive, enterprise applications, IoT devices, and big data analytics. Amazon S3 provides easy-to-use management features so you can organize your data and configure finely-tuned access controls to meet your specific business, organizational, and compliance requirements. 

## STEPS

### DEPLOYING APP TO S3

1. Run ```amplify hosting add```, select a deployment mode ***Hosting with Amplify Console**, and respond to the questions **Manual deployemnt**, 

2. Run ```amplify publish```

3. After the build and deploy finishes, you’ll see a URL for the version of deployed app. Any time you make new changes to the app, just re-run amplify publish
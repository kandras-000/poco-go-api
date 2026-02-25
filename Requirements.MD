Create an api with the following:
1. Use Golang use air to hot reload.
2. Use Postres for the database using docker.
3. Use best practice for ORM or data access.
4. API
    a. Include authentication using JWT
    b. Create register, login
    c. Create a simple send message endpoint with sends a message to a user which is persisted if they're not online and will use websockets to push that notification.
5. Front End
   a. Use Vue 3
   b. Create simple front end to test out the API.


6. Additional requirement:
   a. Make it so each message shows who the message is from.



7. Deployment

   Hostname  julius-clinic.bnr.la
   Primary IP  119.42.52.217
   sftp://root@119.42.52.217

8. New features:
   a. Using the existing tech stack.
   a. Make the app a Progressive Web App "PWA" and handle prompting the user to update when a new version is detected.

   b. Add the following feature for a logged in user:

   * This feature is to upload evidence.
   * File upload feature with nice UX using tailwind, can upload photos, files, videos, audio.
   * Captures geolocation.
   * Make the feature and the entire app mobile friendly and reponsive.
   * Can easily upload a photo, audio, video etc that is taken from a phone.
   * Add a description for the evidence being uploaded.

   c. More details for this feature:
   * Add a text field to enter a name for the container for the evidence, include a timestamp when container is created.
   * This container will be the parent database table under which evidence will be stored a one to many relationship.
   * Add the ability to select an existing container to upload evidence to or create a new container.
   * Make the Home page of the App display a list of existing containers which you can select to add more evidence to, order this by the most recently created ones first.

   
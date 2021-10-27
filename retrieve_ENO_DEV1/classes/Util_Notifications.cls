public inherited sharing class Util_Notifications {
    
    //Send push notificaitons to users
    public static void notifyUsersViaPush(Set<String> recipientsIds, String targetId, String title, String message) {
 
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Shift_Published'
        ];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
 
        // Set the contents for the notification
        notification.setTitle(title);
        notification.setBody(message);
 
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        // Actually send the notification
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
}
trigger ContentDocumentTrigger on ContentDocument (after insert) {

    System.debug('Entering the trigger ---> ');
    List<ContentDocumentLink> contentDocLinkIds = new List<ContentDocumentLink>();

    Map<Id,ContentDocument> contentDocMap = (Map<Id,ContentDocument>)Trigger.newMap;
    System.debug('contentDocMap ---> '  + contentDocMap);

    Set<Id> contentDocIds = new Set<Id>();

    Map<String, Schema.SObjectType> objectsMap  = Schema.getGlobalDescribe();
    String contactPrefix = objectsMap.get('Contact').getDescribe().getKeyPrefix();
    System.debug('contactPrefix ---> '  + contactPrefix);
    System.debug('contentDocMap.keySet() ---> '  + contentDocMap.keySet());
    System.debug('getContentDocRecords(contentDocMap.keySet()) ---> '  + getContentDocRecords(contentDocMap.keySet()));
    System.debug('getContentDocRecords(contentDocMap.keySet()) ---> '  + [select id from ContentVersion]);

    Map<Id, String> contactDownlaodLinkmap = new Map<Id, String>();

    // for(ContentDocument contentDoc :getContentDocRecords(contentDocMap.keySet())){
    // for(ContentDocument contentDoc : [SELECT Id, (SELECT Id, LinkedEntityId FROM ContentDocumentLinks),(SELECT Id, VersionDataUrl FROM ContentVersions ORDER BY CreatedDate Desc LIMIT 1)FROM ContentDocument WHERE Id IN :contentDocMap.keySet()] ){
    for(ContentDocument contentDoc : [SELECT Id FROM ContentDocument WHERE Id IN :contentDocMap.keySet()] ){
        System.debug('contentDoc ---> '  + contentDoc);

            String versionUrl = contentDoc.ContentVersions[0].VersionDataUrl;
            for(ContentDocumentLink contentDocLink : contentDoc.ContentDocumentLinks){

                String linkedEntityPrefix = String.valueOf(contentDocLink.LinkedEntityId).mid(0,3);
                System.debug('linkedEntityPrefix ---> '+ linkedEntityPrefix);
                if(linkedEntityPrefix == contactPrefix){
                    contactDownlaodLinkmap.put(contentDocLink.LinkedEntityId, versionUrl);
                    // contactIdSet.add(contentDocLink.LinkedEntityId);
                }
            }
    }

    List<Account> accountsToUpdate = new List<Account>();

    for(Contact contact :getContacts(contactDownlaodLinkmap.keySet())){
        Account account = new Account();
        System.debug('contact rec --> ' + contact);
        account.Website = contactDownlaodLinkmap.get(contact.Id);
        accountsToUpdate.add(account);
    }

    if(!accountsToUpdate.isEmpty()){
        update accountsToUpdate;
    }

    public static List<Contact> getContacts(Set<Id> contactIds){
        return [
            SELECT Id, AccountId
            FROM Contact 
            WHERE Id IN :contactIds
        ];
    }

    public static List<ContentDocument> getContentDocRecords(Set<Id> contentDocIds){
        return[
            SELECT Id, 
                (
                    SELECT Id, LinkedEntityId FROM ContentDocumentLinks
                ),
                (
                    SELECT Id, VersionDataUrl FROM ContentVersions 
                    ORDER BY CreatedDate Desc LIMIT 1
                )
            FROM ContentDocument
            WHERE Id IN :contentDocMap.keySet()
        ];
    }

}
/**
 * Class Name: ContentVersionHandler
 * Author: Mahanth Veeraraj
 * Created: 
 * Description: Handler class for Content Version Trigger
 */
public class ContentVersionHandler {

    /**
     * **********************************************************************************
     * 
     * Public Methods
     * 
     * **********************************************************************************
     */
    
    /**
     * Mathod Name: updateContactAccountWebsite
     * Paramaters: 
     *  contentVersionList: list of content versions from the ContentVersion trigger after insert 
     * Return: void
     * Description: Checks if the file is associated with the a contact records, get the aprent account of
     * the contact. Updates the accounts website fileds with the content versions download URL
     */
    public static void updateContactAccountWebsite(List<ContentVersion> contentVersionList){
        Map<String, Schema.SObjectType> objectsMap  = Schema.getGlobalDescribe();
        String contactPrefix = objectsMap.get('Contact').getDescribe().getKeyPrefix();

        Map<Id, Id> contactToCvMap = new Map<Id, Id>();

        List<ContentDistribution> contentDistributionList = new List<ContentDistribution> ();

        for(ContentVersion contentVersion : contentVersionList){

            String parentRecordId = String.valueOf(contentVersion.FirstPublishLocationId);

            if(contactPrefix == parentRecordId.mid(0,3)){

                contactToCvMap.put(contentVersion.FirstPublishLocationId, contentVersion.Id);
                ContentDistribution contentDistribution = createContentDistribution(contentVersion);
                contentDistributionList.add(contentDistribution);
            }
        }

        if(contactToCvMap.isEmpty())return;

        insert contentDistributionList;

        Set<Id> contentDistributionIds = new Set<Id>();

        for(ContentDistribution contentDistribution :contentDistributionList){
            contentDistributionIds.add(contentDistribution.Id);
        }

        Map<Id, String> contentDistributionMap = new Map<Id, String> ();

        for(ContentDistribution contentDistribution :getContentDistribution(contentDistributionIds)){
            contentDistributionMap.put(contentDistribution.ContentVersionId, (contentDistribution.ContentDownloadUrl));
        }

        if(contentDistributionMap.isEmpty())return;

        List<Account> accountsToUpdate = new List<Account>();

        for(Contact contact: getContacts(contactToCvMap.keySet())){
            Account account = new Account();
            account.Website = contentDistributionMap.get(contactToCvMap.get(contact.Id));
            accountsToUpdate.add(account);
            account.Id = contact.AccountId;
        }

        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
    }
    /**
     * **********************************************************************************
     * 
     * Private Methods
     * 
     * **********************************************************************************
     */

     /**
      * Method Name: createContentDistribution
      * Paramaters: contentVersion: Content Version record
      * Discription: create a content distribution record for the content version to make it 
      * public and downloadable
      */
    private static ContentDistribution createContentDistribution(ContentVersion contentVersion){
        ContentDistribution contentDistribution = new ContentDistribution();
        contentDistribution.ContentVersionId = contentVersion.Id;
        contentDistribution.Name = contentVersion.Title;
        contentDistribution.PreferencesAllowViewInBrowser = true;
        contentDistribution.PreferencesAllowOriginalDownload = true;
        contentDistribution.PreferencesLinkLatestVersion = true;
        contentDistribution.PreferencesAllowPDFDownload = true;
        return contentDistribution;
    }

    /**
     * Mathod Name: getContentDistribution
     * Paramaters: contentDistributionIds : Set of content distribution ids
     * Description: Getter for content destribution after then insert to retrive the generated 
     * download URL 
     */
    private static List<ContentDistribution> getContentDistribution(Set<Id> contentDistributionIds){
        return [
            SELECT Id, 
                ContentDownloadUrl, 
                ContentVersionId 
            FROM ContentDistribution 
            WHERE Id IN :contentDistributionIds
        ];
    }

    /**
     * Method Name: getContacts
     * Paramaters: contactIds : set of contact Ids 
     * Description: getter for contacts to get the Parent Account Id used to updated the
     * account website with the file download URL 
     */
    private static List<Contact> getContacts(Set<Id> contactIds){
        return [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE Id IN :contactIds
        ];
    }

}
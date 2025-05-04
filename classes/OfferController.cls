public with sharing class OfferController {
    @AuraEnabled(cacheable=true)
    public static List<Contract__c> getContracts(Id offerId) {
        return [SELECT Id, Subject__c, Value__c, Investor__c FROM Contract__c WHERE Offer__c = :offerId];
    }

    @AuraEnabled(cacheable=true)
    public static List<Team_Member__c> getTeamMembers(Id offerId) {
        return [SELECT Id, Full_Name__c, Task_Assigned__c, Birth_Year__c, Education__c, Experience_Years__c, Licenses__c FROM Team_Member__c WHERE Offer__c = :offerId];
    }

    /**
     * Method for creating the offer record and linking uploaded files.  Also creates related Contracts and Team Members.
     * @param tenderId The Tender Id.
     * @param pricing The price of the offer.
     * @param similarExperience Previous experience if applicable. Can be null.
     * @param eligibility Eligibility for this offer. Default true.
     * @param conflictFree Conflicting interest if applicable. Default false.
     * @param fileDocumentIds List of ContentDocument IDs of the uploaded files.
     * @param contractsData List of Contract data (Subject__c, Value__c, Investor__c).
     * @param teamMembersData List of Team Member data (Full_Name__c, Task_Assigned__c, Birth_Year__c, Education__c, Experience_Years__c, Licenses__c, MemberDocuments).
     * @return The ID of the newly created Offer__c record.
     */
   @AuraEnabled
public static Id createOfferWithFiles(
    Id tenderId,
    Decimal pricing,
    String similarExperience,
    Boolean eligibility,
    Boolean conflictFree,
    List<Id> fileDocumentIds,
    List<Map<String, Object>> contractsData,
    List<Map<String, Object>> teamMembersData
) {
    try {
        // Create Offer
        Offer__c newOffer = new Offer__c(
            Tender__c = tenderId,
            Pricing__c = pricing,
            Similar_Experience__c = similarExperience,
            Eligibility_Declaration__c = eligibility ? 'Eligible' : 'Non-Eligible',
            Conflict_of_Interest__c = conflictFree,
            Submission_Date__c = DateTime.now(),
            Status__c = 'Submitted',
            Vendor__c = UserInfo.getUserId() != null ? 
                [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Contact.AccountId : 
                [SELECT Id FROM Account WHERE Name = 'Inclusive Account' LIMIT 1].Id
        );
        insert newOffer;

        // Link Offer Files
        if (fileDocumentIds != null && !fileDocumentIds.isEmpty()) {
            List<ContentDocumentLink> offerLinks = new List<ContentDocumentLink>();
            for (Id docId : fileDocumentIds) {
                offerLinks.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId = newOffer.Id,
                    ShareType = 'V'
                ));
            }
            insert offerLinks;
        }

        // Create Contracts
        if (contractsData != null && !contractsData.isEmpty()) {
            List<Contract__c> contractsToInsert = new List<Contract__c>();
            for (Map<String, Object> contractData : contractsData) {
                contractsToInsert.add(new Contract__c(
                    Offer__c = newOffer.Id,
                    Subject__c = (String) contractData.get('Subject__c'),
                    Value__c = (Decimal) contractData.get('Value__c'),
                    Investor__c = (String) contractData.get('Investor__c')
                ));
            }
            insert contractsToInsert;
        }

        // Create Team Members
        if (teamMembersData != null && !teamMembersData.isEmpty()) {
            List<Team_Member__c> teamMembersToInsert = new List<Team_Member__c>();
            for (Map<String, Object> memberData : teamMembersData) {
                teamMembersToInsert.add(new Team_Member__c(
                    Offer__c = newOffer.Id,
                    Full_Name__c = (String) memberData.get('Full_Name__c'),
                    Task_Assigned__c = (String) memberData.get('Task_Assigned__c'),
                    Birth_Year__c = (Decimal) memberData.get('Birth_Year__c'),
                    Education__c = (String) memberData.get('Education__c'),
                    Experience_Years__c = (Decimal) memberData.get('Experience_Years__c'),
                    Licenses__c = (String) memberData.get('Licenses__c')
                ));
            }

            insert teamMembersToInsert;

            // Link files to Team Members
            List<ContentDocumentLink> memberLinksToInsert = new List<ContentDocumentLink>();
            for (Integer i = 0; i < teamMembersToInsert.size(); i++) {
                Team_Member__c member = teamMembersToInsert[i];
                Map<String, Object> memberData = teamMembersData[i];
                List<Object> rawDocIds = (List<Object>) memberData.get('MemberDocuments');
                if (rawDocIds != null) {
                    for (Object docId : rawDocIds) {
                        memberLinksToInsert.add(new ContentDocumentLink(
                            ContentDocumentId = (Id) docId,
                            LinkedEntityId = member.Id,
                            ShareType = 'V'
                        ));
                    }
                }
            }

            if (!memberLinksToInsert.isEmpty()) {
                insert memberLinksToInsert;
            }
        }

        return newOffer.Id;

    } catch (Exception e) {
        throw new AuraHandledException('Error creating offer and related records: ' + e.getMessage());
    }
}


    /**
     * @deprecated Use createOfferWithFiles instead.
     */
    @AuraEnabled
    public static Id createOffer(Id tenderId, Decimal pricing, String similarExperience, Boolean eligibility, Boolean conflictFree) {
        return createOfferWithFiles(tenderId, pricing, similarExperience, eligibility, conflictFree, null, null, null);
    }

    /**
     * Fetches the picklist values for the Task_Assigned__c field on the Team_Member__c object.
     * @return List of picklist values with label and value.
     */
    @AuraEnabled(cacheable=true)
    public static List<Object> getTaskAssignedPicklistValues() {
        List<Object> picklistValues = new List<Object>();
        Schema.DescribeFieldResult fieldDescribe = Team_Member__c.Task_Assigned__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            Map<String, Object> picklistValue = new Map<String, Object>();
            picklistValue.put('label', entry.getLabel());
            picklistValue.put('value', entry.getValue());
            picklistValues.add(picklistValue);
        }
        return picklistValues;
    }
}
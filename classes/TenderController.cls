public class TenderController {
    @AuraEnabled(cacheable=true)
    public static List<Tender__c> getTenders() {
        return [
            SELECT Id, Name, Ceiling_Fund__c, Deadline__c, Status__c
            FROM Tender__c
            WHERE Status__c = 'Published'
            ORDER BY Name
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static Tender__c getTenderById(String recordId) {
        try {
            return [
                SELECT Id, Name, Ceiling_Fund__c, Deadline__c, Status__c
                FROM Tender__c
                WHERE Id = :recordId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Unable to fetch tender: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createTender(String name, Decimal ceilingFund, Date deadline, String criteria, String teamRequirements, String qualifyingCriteria) {
        Tender__c tender = new Tender__c(
            Name = name,
            Ceiling_Fund__c = ceilingFund,
            Deadline__c = deadline,
            Criteria__c = criteria,
            Core_Team_Requirements__c = teamRequirements,
            Qualifying_Criteria__c = qualifyingCriteria,
            Status__c = 'Draft'
        );
        insert tender;
        return tender.Id;
    }
}
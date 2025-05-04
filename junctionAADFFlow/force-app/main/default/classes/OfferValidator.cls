/**
 * Created by visjanqorri on 4.5.25.
 */

public class OfferValidator {
    public static void validateOffers(List<Offer__c> offers, Boolean isInsert) {
        Set<Id> offerIds = new Set<Id>();
        for (Offer__c offer : offers) {
            if (!isInsert && offer.Id != null) {
                offerIds.add(offer.Id);
            }
        }

        // Query related Contract__c and Team_Member__c
        Map<Id, List<Contract__c>> contractsByOffer = new Map<Id, List<Contract__c>>();
        Map<Id, List<Team_Member__c>> teamMembersByOffer = new Map<Id, List<Team_Member__c>>();
        if (!offerIds.isEmpty()) {
            for (Contract__c contract : [SELECT Id, Offer__c, Value__c FROM Contract__c WHERE Offer__c IN :offerIds]) {
                if (!contractsByOffer.containsKey(contract.Offer__c)) {
                    contractsByOffer.put(contract.Offer__c, new List<Contract__c>());
                }
                contractsByOffer.get(contract.Offer__c).add(contract);
            }
            for (Team_Member__c member : [SELECT Id, Offer__c, Task_Assigned__c, Experience_Years__c FROM Team_Member__c WHERE Offer__c IN :offerIds]) {
                if (!teamMembersByOffer.containsKey(member.Offer__c)) {
                    teamMembersByOffer.put(member.Offer__c, new List<Team_Member__c>());
                }
                teamMembersByOffer.get(member.Offer__c).add(member);
            }
        }

        for (Offer__c offer : offers) {
            List<String> missing = new List<String>();

            // Check Contracts
            Integer contractCount = contractsByOffer.get(offer.Id)?.size() ?? 0;
            if (contractCount < 1) {
                missing.add('At least one in-process contract required');
            } else if (!isInsert) {
                for (Contract__c contract : contractsByOffer.get(offer.Id) ?? new List<Contract__c>()) {
                    if (contract.Value__c == null) {
                        missing.add('Contract missing value');
                    }
                }
            }

            // Check Team Members
            Boolean hasLandscapeArchitect = false;
            for (Team_Member__c member : teamMembersByOffer.get(offer.Id) ?? new List<Team_Member__c>()) {
                if (member.Task_Assigned__c == 'Landscape Architect') {
                    hasLandscapeArchitect = true;
                    if (member.Experience_Years__c < 10) {
                        missing.add('Landscape Architect lacks 10 years experience');
                    }
                }
            }
            if (!hasLandscapeArchitect) {
                missing.add('Missing Landscape Architect');
            }

            // File validation only in before update
            if (!isInsert && offer.Id != null && !offerIds.isEmpty()) {
                List<ContentDocumentLink> files = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :offer.Id];
                if (files.isEmpty()) {
                    missing.add('Missing QKB extract or payroll');
                }
            }

            offer.Missing_Info__c = missing.isEmpty() ? null : String.join(missing, ', ');
        }
    }
}
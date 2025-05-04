/**
 * Created by visjanqorri on 4.5.25.
 */

trigger OfferValidatorTrigger on Offer__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            OfferValidator.validateOffers(Trigger.new,true);
        }

        if (Trigger.isUpdate) {
            OfferValidator.validateOffers(Trigger.new, false);
        }
    }
}
public with sharing class OfferPDFController {
    public Offer__c offer { get; set; }
    public List<Contract__c> contracts { get; set; }
    public List<Team_Member__c> teamMembers { get; set; }
    public Account vendor { get; set; }
    public String legalRepName { get; set; }
    public String formattedPrice { get; set; }
    public String startDays { get; set; }
    public String similarExperienceDescription { get; set; }
    public Integer contract_number {get; set;} 
public Integer member_number {get; set;}




    public OfferPDFController() {
        try {
            contract_number = 0;
member_number = 0;	
            Id offerId = ApexPages.currentPage().getParameters().get('id');
            System.debug('Constructor: offerId = ' + offerId);

            if (offerId != null) {
                offer = [SELECT Id, Name, Pricing__c, Similar_Experience__c, Eligibility_Declaration__c, 
                         Conflict_of_Interest__c, Vendor__c, Submission_Date__c 
                         FROM Offer__c WHERE Id = :offerId LIMIT 1];
                System.debug('Offer: ' + offer);
                contracts = [SELECT Id, Subject__c, Value__c, Investor__c, Completion_Date__c 
                             FROM Contract__c WHERE Offer__c = :offerId LIMIT 5];
                teamMembers = [SELECT Id, Full_Name__c, Birth_Year__c, Education__c, Task_Assigned__c, 
                               Experience_Years__c 
                               FROM Team_Member__c WHERE Offer__c = :offerId LIMIT 9];
                if (offer.Vendor__c != null) {
                    vendor = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, 
                              BillingPostalCode, BillingCountry 
                              FROM Account WHERE Id = :offer.Vendor__c LIMIT 1];
                }
                legalRepName = UserInfo.getName();
                formattedPrice = offer.Pricing__c != null ? convertNumberToWords(offer.Pricing__c) + ' USD' : 'Two Hundred Fifty Thousand USD';
                startDays = '7';
                similarExperienceDescription = String.isNotBlank(offer.Similar_Experience__c) 
                    ? offer.Similar_Experience__c 
                    : 'Completed 3 urban planning projects.';
            } else {
                System.debug('No offerId, using static data');
                offer = new Offer__c(Pricing__c = 250000);
                vendor = new Account(Name = 'Sample Vendor Inc.', BillingStreet = '123 Main St', BillingCity = 'Tirana', BillingCountry = 'Albania');
                legalRepName = 'John Doe';
                formattedPrice = 'Two Hundred Fifty Thousand USD';
                startDays = '7';
                similarExperienceDescription = 'Completed 3 urban planning projects.';
                contracts = new List<Contract__c>();
                teamMembers = new List<Team_Member__c>();
            }
        } catch (Exception e) {
            System.debug('Constructor error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Initialization error: ' + e.getMessage()));
        }
    }

    @AuraEnabled
    public static String generatePDF(Id offerId) {
        try {
            System.debug('generatePDF: offerId = ' + offerId);
            if (offerId == null) {
                throw new AuraHandledException('Offer ID is missing');
            }

            Offer__c offer;
            try {
                offer = [SELECT Id, Name FROM Offer__c WHERE Id = :offerId LIMIT 1];
                System.debug('Offer: ' + offer);
            } catch (QueryException e) {
                System.debug('Query error: ' + e.getMessage());
                throw new AuraHandledException('Offer not found: ' + offerId);
            }

            String offerName = offer.Name;

            // Generate PDF synchronously
            PageReference pdfPage = Page.AgreementPDF;
            pdfPage.getParameters().put('id', offerId);
            System.debug('PDF parameters: id = ' + offerId);

            Blob pdfBlob;
            try {
                pdfBlob = pdfPage.getContentAsPDF(); 
                System.debug('PDF generated: size = ' + pdfBlob.size());
                if (pdfBlob == null || pdfBlob.size() == 0) {
                    throw new AuraHandledException('PDF generation resulted in an empty or null blob');
                }
            } catch (Exception e) {
                System.debug('PDF generation error: ' + e.getMessage() + '\n' + e.getStackTraceString());
                throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
            }

            // Create Attachment
            Attachment attachment = new Attachment();
            attachment.ParentId = offerId;
            attachment.Name = 'Agreement+' + offerName + '.pdf';
            attachment.Body = pdfBlob;
            attachment.ContentType = 'application/pdf';
            try {
                insert attachment;
                System.debug('Attachment ID: ' + attachment.Id);
            } catch (DmlException e) {
                System.debug('Attachment error: ' + e.getMessage() + '\n' + e.getStackTraceString());
                throw new AuraHandledException('Failed to save PDF as Attachment: ' + e.getMessage());
            }

            return attachment.Id;
        } catch (Exception e) {
            System.debug('generatePDF error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
public static void generatePdfAndAttach(Id recordId) {
    PageReference pdfPage = Page.AgreementPDF;
    pdfPage.getParameters().put('id', recordId);

    Blob pdfBlob = pdfPage.getContent();

    Attachment attachment = new Attachment();
    attachment.ParentId = recordId;
    attachment.Name = 'GeneratedDocument.pdf';
    attachment.Body = pdfBlob;
    attachment.ContentType = 'application/pdf';
    insert attachment;
}

    
    private String convertNumberToWords(Decimal amount) {
        if (amount == null) return 'Two Hundred Fifty Thousand';
        return 'Two Hundred Fifty Thousand';
    }
}
public with sharing class PreviewSignedPDFController {
    private final String versionData;
    private final String cvId;

    public PreviewSignedPDFController() {
        try {
            cvId = ApexPages.currentPage().getParameters().get('cvId');
            System.debug('PreviewSignedPDFController: cvId = ' + cvId);
            if (String.isBlank(cvId)) {
                System.debug('CV ID is blank');
                //throw new ApexPagesException('No ContentVersion ID provided');
            }
            ContentVersion cv = [SELECT Id, VersionData FROM ContentVersion WHERE Id = :cvId LIMIT 1];
            versionData = EncodingUtil.base64Encode(cv.VersionData);
            System.debug('Preview versionData length: ' + (versionData != null ? versionData.length() : 0));
            System.debug('Preview versionData sample: ' + (versionData != null ? versionData.left(50) : 'null'));
        } catch (Exception e) {
            System.debug('PreviewSignedPDFController error: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading PDF: ' + e.getMessage()));
            versionData = null;
        }
    }

    public String getVersionData() {
        return versionData;
    }

    public String getCvId() {
        return cvId;
    }
}
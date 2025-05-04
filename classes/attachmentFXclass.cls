// Apex Class: attachmentFXclass.cls
public with sharing class attachmentFXclass {
    @AuraEnabled
    public static String addSignature(Id recordId, String data, String documentType) {
        if (String.isBlank(data) || recordId == null) {
            return 'Error: Signature data or Record ID cannot be blank.';
        }

        try {
            if (documentType == 'Attachment') {
                return addAttachment(recordId, data);
            } else if (documentType == 'SF File') {
                return saveRecordFile(recordId, data);
            } else {
                return 'Error: Invalid document type specified.';
            }
        } catch (Exception e) {
            return 'Error saving signature: ' + e.getMessage();
        }
    }

    private static String addAttachment(Id parentId, String base64Data) {
        Attachment attach = new Attachment();
        attach.ParentId = parentId;
        attach.Name = 'Signature_' + DateTime.now().format('yyyyMMdd_HHmmss') + '.png';
        attach.Body = EncodingUtil.base64Decode(base64Data.substringAfter(','));
        attach.ContentType = 'image/png';
        insert attach;
        return 'Signature saved as attachment successfully.';
    }

    private static String saveRecordFile(Id parentId, String base64Data) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Signature_' + DateTime.now().format('yyyyMMdd_HHmmss');
        cv.VersionData = EncodingUtil.base64Decode(base64Data.substringAfter(','));
        cv.PathOnClient = cv.Title + '.png';
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id].Id;
        cdl.LinkedEntityId = parentId;
        cdl.ShareType = 'V'; // Viewer permission
        insert cdl;

        return 'Signature saved as Salesforce File successfully.';
    }
}
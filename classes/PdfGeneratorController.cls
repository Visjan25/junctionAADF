/**
* @File Name : PdfGeneratorController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 4, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 4, 2025 |   | Initial Version
**/

public class PdfGeneratorController {
	@AuraEnabled
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

}
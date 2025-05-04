import { LightningElement, api } from 'lwc';
import generatePdfAndAttach from '@salesforce/apex/PdfGeneratorController.generatePdfAndAttach';

export default class PdfGeneratorButton extends LightningElement {
    @api recordId;

    handleClick() {
        generatePdfAndAttach({ recordId: this.recordId })
            .then(() => {
       
                alert('PDF generated and attached successfully!');
            })
            .catch(error => {
                console.error('Error generating PDF:', error);
                // eslint-disable-next-line no-alert
                alert('Error generating PDF.');
            });
    }
}
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTenderById from '@salesforce/apex/TenderController.getTenderById';

export default class TenderDetail extends LightningElement {
    @api recordId;
    @track record;
    @track error;
    @track internalRecordId; // Fallback for URL parameter

    connectedCallback() {
        // Log initial recordId
        console.log('tenderDetail initial recordId:', this.recordId);
        
        // Fallback: Extract recordId from URL if not bound
        if (!this.recordId) {
            const urlParams = new URLSearchParams(window.location.search);
            this.internalRecordId = urlParams.get('recordId');
            console.log('Extracted recordId from URL:', this.internalRecordId);
            if (this.internalRecordId) {
                this.recordId = this.internalRecordId; // Set recordId for @wire
            }
        }
    }

    @wire(getTenderById, { recordId: '$recordId' })
    wiredTender({ error, data }) {
        console.log('getTenderById called with recordId:', this.recordId);
        if (data) {
            console.log('Tender record:', JSON.stringify(data));
            this.record = data;
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching tender:', JSON.stringify(error));
            this.error = error.body?.message || 'Failed to load tender';
            this.record = undefined;
            this.showToast('Error', this.error, 'error');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}
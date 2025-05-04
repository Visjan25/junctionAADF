import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTenders from '@salesforce/apex/TenderController.getTenders';
//import isGuestUser from '@salesforce/user/isGuestUser'; // Removed this
import { getRecord } from 'lightning/uiRecordApi'; //Added this

const fields = ['User.IsGuest'];
export default class TenderList extends NavigationMixin(LightningElement) {
    @track tenders = [];
    @track filteredTenders = [];
    @track searchKey = '';
    @track columns = [
        {
            label: 'Tender Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank',
                tooltip: 'View Tender'
            },
            sortable: true
        },
        { label: 'Ceiling Fund (USD)', fieldName: 'Ceiling_Fund__c', type: 'currency', sortable: true },
        { label: 'Deadline', fieldName: 'Deadline__c', type: 'date', sortable: true },
        { label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true }
    ];

    @track isGuestUser = false; // Default

    @wire(getRecord, { recordId: '$userId', fields })
    userDetails({ error, data }) {
        if (data) {
            this.isGuestUser = data.fields.IsGuest.value;
        } else if (error) {
            console.error('Failed to retrieve user details', error);
            this.isGuestUser = false;
        }
    }

    get userId() {
        return '0050k000005k7FBAAY'; //Hardcoded User Id
    }


    @wire(getTenders, { isGuestUser: '$isGuestUser' })
    wiredTenders({ error, data }) {
        if (data) {
            console.log('Raw tenders:', JSON.stringify(data));
            this.tenders = data
                .filter(tender => tender.Status__c === 'Published')
                .map(tender => ({
                    ...tender,
                    recordLink: '/tenderdetailpage?recordId=' + tender.Id // Fallback
                }));
            this.filteredTenders = [...this.tenders];
            this.generateRecordLinks();
        } else if (error) {
            console.error('Error fetching tenders:', JSON.stringify(error));
            this.tenders = [];
            this.filteredTenders = [];
            this.showToast('Error', error.body?.message || 'Failed to load tenders', 'error');
        }
    }

    async generateRecordLinks() {
        try {
            const updatedTenders = await Promise.all(
                this.tenders.map(async tender => {
                    const url = await this[NavigationMixin.GenerateUrl]({
                        type: 'standard__namedPage',
                        attributes: {
                            pageName: 'tenderdetailpage' //  pageName
                        },
                        state: {
                            recordId: tender.Id
                        }
                    });
                    return { ...tender, recordLink: url || '/tenderdetailpage?recordId=' + tender.Id };
                })
            );
            this.tenders = updatedTenders;
            this.filteredTenders = [...updatedTenders];
            console.log('Tenders with links:', JSON.stringify(this.tenders));
            if (this.searchKey) {
                this.handleSearchChange({ target: { value: this.searchKey } });
            }
        } catch (error) {
            console.error('Error generating URLs:', JSON.stringify(error));
            this.showToast('Error', 'Failed to generate tender links: ' + error.message, 'error');
        }
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.filteredTenders = this.tenders.filter(tender =>
            tender.Name?.toLowerCase().includes(this.searchKey)
        );
        console.log('Filtered tenders:', JSON.stringify(this.filteredTenders));
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
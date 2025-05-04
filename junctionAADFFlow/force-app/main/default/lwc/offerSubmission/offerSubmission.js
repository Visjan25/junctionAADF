// offerSubmission.js
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createOfferWithFiles from '@salesforce/apex/OfferController.createOfferWithFiles';
import getTaskAssignedPicklistValues from '@salesforce/apex/OfferController.getTaskAssignedPicklistValues';

export default class OfferSubmission extends LightningElement {
  recordId = null;
  pricing = '';
  similarExperience = '';
  eligibility = false;
  conflictFree = false;
  uploadedFileIds = [];
  @track contracts = [{ Subject__c: '', Value__c: null, Investor__c: '' }];
  @track teamMembers = [{ Full_Name__c: '', Task_Assigned__c: '', options: [], Birth_Year__c: null, Education__c: '', Experience_Years__c: null, Licenses__c: '', MemberDocuments: [] }];
  @track taskAssignedOptions = [];

  connectedCallback() {
    try {
      const urlParams = new URLSearchParams(window.location.search);
      this.recordId = urlParams.get('recordId');
      if (!this.recordId) {
        console.warn('OfferSubmission: Tender Record ID not found in URL parameters.');
      } else {
        console.log('OfferSubmission: Loaded for Tender ID:', this.recordId);
      }
    } catch (error) {
      console.error('OfferSubmission: Error parsing URL parameters:', error);
    }
  }

  @wire(getTaskAssignedPicklistValues)
  wiredTaskAssignedPicklistValues({ error, data }) {
    if (data) {
      this.taskAssignedOptions = data;
      this.teamMembers = this.teamMembers.map(member => ({
        ...member,
        options: this.taskAssignedOptions
      }));
    } else if (error) {
      console.error('Error fetching picklist values:', error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: 'Failed to load Task Assigned picklist values.',
          variant: 'error',
        })
      );
    }
  }

  handlePricingChange(event) {
    this.pricing = event.target.value;
  }

  handleSimilarExperienceChange(event) {
    this.similarExperience = event.target.value;
  }

  handleEligibilityChange(event) {
    this.eligibility = event.target.checked;
  }

  handleConflictFreeChange(event) {
    this.conflictFree = event.target.checked;
  }

  handleFileUpload(event) {
    const uploadedFiles = event.detail.files;
    this.uploadedFileIds = uploadedFiles.map(file => file.documentId);
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: uploadedFiles.length + ' Documents uploaded',
        variant: 'success',
      })
    );
  }

  handleContractChange(event) {
    const index = parseInt(event.target.dataset.index, 10);
    const field = event.target.name;
    const contracts = [...this.contracts];
    contracts[index] = { ...contracts[index] };
    contracts[index][field] = field === 'Value__c' ? Number(event.target.value) : event.target.value;
    this.contracts = contracts;
  }

  addContract() {
    this.contracts = [...this.contracts, { Subject__c: '', Value__c: null, Investor__c: '' }];
  }

  removeContract(event) {
    const index = parseInt(event.target.dataset.index, 10);
    this.contracts = this.contracts.filter((_, i) => i !== index);
  }

  handleTeamMemberChange(event) {
    const index = parseInt(event.target.dataset.index, 10);
    const field = event.target.name;
    const teamMembers = [...this.teamMembers];
    teamMembers[index] = { ...teamMembers[index] };

    if (field === 'Birth_Year__c' || field === 'Experience_Years__c') {
      teamMembers[index][field] = Number(event.target.value);
    } else {
      teamMembers[index][field] = event.target.value;
    }

    this.teamMembers = teamMembers;
  }

  handleMemberFileUpload(event) {
    const index = parseInt(event.target.dataset.index, 10);
    const uploadedFiles = event.detail.files;
    const fileIds = uploadedFiles.map(file => file.documentId);

    const teamMembers = [...this.teamMembers];
    teamMembers[index] = { ...teamMembers[index] };
    teamMembers[index].MemberDocuments = fileIds;
    this.teamMembers = teamMembers;

    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: uploadedFiles.length + ' Documents uploaded for Team Member',
        variant: 'success',
      })
    );
  }

  addTeamMember() {
    this.teamMembers = [...this.teamMembers, {
      Full_Name__c: '',
      Task_Assigned__c: '',
      options: this.taskAssignedOptions,
      Birth_Year__c: null,
      Education__c: '',
      Experience_Years__c: null,
      Licenses__c: '',
      MemberDocuments: []
    }];
  }

  removeTeamMember(event) {
    const index = parseInt(event.target.dataset.index, 10);
    this.teamMembers = this.teamMembers.filter((_, i) => i !== index);
  }

  async submitOffer() {
    if (!this.recordId) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: 'Cannot submit offer: Tender ID was not found in the page URL.',
          variant: 'error',
        })
      );
      return;
    }

    const contractsData = this.contracts.map(contract => ({
      Subject__c: contract.Subject__c,
      Value__c: contract.Value__c,
      Investor__c: contract.Investor__c
    }));

    const teamMembersData = this.teamMembers.map(member => ({
      Full_Name__c: member.Full_Name__c,
      Task_Assigned__c: member.Task_Assigned__c,
      Birth_Year__c: member.Birth_Year__c,
      Education__c: member.Education__c,
      Experience_Years__c: member.Experience_Years__c,
      Licenses__c: member.Licenses__c,
      MemberDocuments: member.MemberDocuments
    }));

    try {
      const offerId = await createOfferWithFiles({
        tenderId: this.recordId,
        pricing: this.pricing,
        similarExperience: this.similarExperience,
        eligibility: this.eligibility,
        conflictFree: this.conflictFree,
        fileDocumentIds: this.uploadedFileIds,
        contractsData: contractsData,
        teamMembersData: teamMembersData,
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: `Offer submitted! ID: ${offerId}${this.uploadedFileIds.length > 0 ? ' and files attached.' : ''}${this.contracts.length > 0 ? ' and contracts created.' : ''}${this.teamMembers.length > 0 ? ' and team members created.' : ''}`,
          variant: 'success',
        })
      );

      // Reset form
      this.pricing = '';
      this.similarExperience = '';
      this.eligibility = false;
      this.conflictFree = false;
      this.uploadedFileIds = [];
      this.contracts = [{ Subject__c: '', Value__c: null, Investor__c: '' }];
      this.teamMembers = [{
        Full_Name__c: '',
        Task_Assigned__c: '',
        options: this.taskAssignedOptions,
        Birth_Year__c: null,
        Education__c: '',
        Experience_Years__c: null,
        Licenses__c: '',
        MemberDocuments: []
      }];
    } catch (error) {
      let errorMessage = 'Unknown error';
      if (error?.body?.message) {
        errorMessage = error.body.message;
        if (error.body.output?.errors?.length > 0) {
          errorMessage = error.body.output.errors[0].message;
        } else if (error.body.pageErrors?.length > 0) {
          errorMessage = error.body.pageErrors[0].message;
        }
      } else if (typeof error === 'string') {
        errorMessage = error;
      } else if (error?.message) {
        errorMessage = error.message;
      }

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error Creating Offer',
          message: errorMessage,
          variant: 'error',
          mode: 'sticky',
        })
      );
      console.error('Error submitting offer:', JSON.stringify(error));
    }
  }
}

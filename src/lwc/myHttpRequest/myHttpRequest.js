import { LightningElement } from 'lwc';
import vTable from './table';
import { TABLE_CONFIG, WND_CONFIG, HPPT_METHODS, NOTIFICATIONS, BATCH_TYPES } from './helpers'
import getRequests from '@salesforce/apex/MyHttpController.getRequests';
import sendRequest from '@salesforce/apex/MyHttpController.sendRequest';
import getListOfBatches from '@salesforce/apex/MyHttpController.getListOfBatches';
import runBatch from '@salesforce/apex/MyHttpController.runBatch';
import stopBatch from '@salesforce/apex/MyHttpController.stopBatch';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MyHttpRequest extends LightningElement {
    dateFrom = new Date().toISOString();
    repeat = false;
    vtable;
    selectedRow;
    firstRender = true;
    showRequestWnd = false;
    showBatchWnd = false;
    disabledWnd = false;

    httpMethods = HPPT_METHODS;
    showAllData = false;
    headers = [];
    queryParams = [];
    formData = [];
    batches = [];
    httpBody;
    httpMethod;
    httpUrl;

    batchTypes = BATCH_TYPES;
    batchType;
    batchRepeatAfterMin;
    batchRepeat = false;

    get isSelected () {
        return !this.selectedRow;
    }

    get repeatNeed () {
        return this.selectedRow?.Repeat__c == 0 ? 'No' : 'Yes';
    }

    get numberOfRequestsSent () {
        return parseInt(this.selectedRow?.NumberOfAttempts__c) + 1;
    }

    async renderedCallback() {
        if (this.firstRender) {
            this.firstRender = false;
            this.loadTable();
            this.loadData();
        }
    }

    loadTable() {
        if (this.vtable) return;

        this.vtable = new vTable({
            ...TABLE_CONFIG,
            node: this.template.querySelector('.myHttpRequestTable'),
            numberOfVisibleRows: parseInt((window.innerHeight - 450) / TABLE_CONFIG.rowHeight),
            data: [],
            onRowClick: this.selectRow.bind(this)
        });
    }

    async loadData() {
        if (!this.vtable) return;

        this.vtable.loadingStart();
        try {
            const data = await getRequests({fromDate: this.dateFrom.replace(/[T,Z]/g, ' '), repeat: this.repeat});
            this.vtable.setData(data);
            this.vtable.setFooterContent('row count: ' + this.vtable.getRowCount());
            this.vtable.loadingStop();
        } catch (e) {
            console.error(e);
        }
        this.vtable.loadingStop();
    }

    selectRow(row) {
        if (this.selectedRow?.Name__c === row?.Name__c) {
            this.selectedRow = null;
            this.vtable.removeSelection();
        } else {
            this.selectedRow = row;
        }
    }

    parseData(data) {
        if (!data) return [];
        const params = []
        const keyValueArr = data.split('&');
        keyValueArr.forEach(keyVal => {
            const dataArr = keyVal.split('=');
            params.push({
                id: `${Date.now()}-${params.length}`,
                name: dataArr[0],
                value: dataArr[1],
            })
        })

        return params;
    }

    omshowRequestWnd(config) {
        this.showRequestWnd = true;
        this.wndTitle = config.title;
    }
    // Actions
    handleShowAllData() {
        if (!this.selectedRow) return;
        this.setData();
        this.showAllData = true;
        this.disabledWnd = true;
        this.omshowRequestWnd(WND_CONFIG.showAllData);
    }

    handleCreateRequest() {
        this.cleanData();
        this.omshowRequestWnd(WND_CONFIG.createRequest);
    }

    handleRepeatRequest() {
        this.setData();
        this.omshowRequestWnd(WND_CONFIG.repeatRequest);
    }

    handleCloseWnd() {
        this.showRequestWnd = false;
        this.showBatchWnd = false;
        this.disabledWnd = false;
        this.showAllData = false;
    }

    cleanData() {
        this.httpUrl = null;
        this.httpMethod = null;
        this.httpBody = null;
        this.queryParams = [];
        this.headers = [];
        this.formData = [];
    }

    setData() {
        this.httpUrl = this.selectedRow?.Url__c;
        this.httpMethod = this.selectedRow?.Method__c;
        this.httpBody = this.selectedRow?.Body__c;

        this.queryParams = this.parseData(this.selectedRow?.QueryParam__c);
        this.headers = this.parseData(this.selectedRow?.Headers__c);
        this.formData = this.parseData(this.selectedRow?.FormData__c);
    }

    handSelectDate(e) {
        this.dateFrom = e.target.value;
    }

    handleSlesctRepeat() {
        this.repeat = !this.repeat;
    }

    showNotification(config) {
        this.dispatchEvent(new ShowToastEvent(config));
    }

    // METHOD ADN URL
    handleSetHttpMethod(e) {
        this.httpMethod = e.detail.value;
    }

    handleSetUrl(e) {
        this.httpUrl = e.detail.value;
    }

    // HEADERS
    handlerAddHeader() {
        this.headers = [...this.headers, {
            id: `${Date.now()}-${this.headers.length}`,
            name: null,
            value: null,
        }]
    }

    handlerDeleteHeader(e) {
        const id = e.target.dataset.id;
        this.headers = this.headers.filter(header => header.id !== id);
    }

    handleSetHeaderName(e) {
        const id = e.target.dataset.id;
        const header = this.headers.find(header => header.id === id);
        header.name = e.target.value;
    }

    handleSetHeaderValue(e) {
        const id = e.target.dataset.id;
        const header = this.headers.find(header => header.id === id);
        header.value = e.target.value;
    }

    // QUERY PARAM
    handlerAddQueryParam() {
        this.queryParams = [...this.queryParams, {
            id: `${Date.now()}-${this.queryParams.length}`,
            name: null,
            value: null,
        }]
    }

    handlerDeleteQueryParam(e) {
        const id = e.target.dataset.id;
        this.queryParams = this.queryParams.filter(param => param.id !== id);
    }

    handleSetQueryParamName(e) {
        const id = e.target.dataset.id;
        const param = this.queryParams.find(param => param.id === id);
        param.name = e.target.value;
    }

    handleSetQueryParamValue(e) {
        const id = e.target.dataset.id;
        const param = this.queryParams.find(param => param.id === id);
        param.value = e.target.value;
    }

    // FORM DATA
    handlerAddFormData() {
        this.formData = [...this.formData, {
            id: `${Date.now()}-${this.formData.length}`,
            name: null,
            value: null,
        }]
    }

    handlerDeleteFormData(e) {
        const id = e.target.dataset.id;
        this.formData = this.formData.filter(item => item.id !== id);
    }

    handleSetFormDataName(e) {
        const id = e.target.dataset.id;
        const item = this.formData.find(item => item.id === id);
        item.name = e.target.value;
    }

    handleSetFormDataValue(e) {
        const id = e.target.dataset.id;
        const item = this.formData.find(item => item.id === id);
        item.value = e.target.value;
    }

    // Body
    handleSetBody(e) {
        this.httpBody = e.target.value;
    }

    // Wnd Actions
    async handleSendRequest() {
        if (this.sendRequestValidation()) return;
        this.disabledWnd = true;

        try {
            const jsonData = JSON.stringify({
                url: this.httpUrl,
                method: this.httpMethod,
                headers: this.headers.filter(h => h.name && h.value),
                formData: this.formData.filter(fd => fd.name && fd.value),
                queryParams:  this.queryParams.filter(qp => qp.name && qp.value),
                body: this.httpBody,
            });

            console.log(jsonData);

            this.showNotification(NOTIFICATIONS.waiting);
            await sendRequest({jsonData});
            this.showNotification({...NOTIFICATIONS.requestSuccess});
            this.loadData();
        } catch (e) {
            this.showNotification({...NOTIFICATIONS.requestError, message: e.body.message});
            console.error(e)
        }

        this.disabledWnd = false;
    }

    sendRequestValidation() {
        let error = false;
        if (!this.httpUrl) {
            this.showNotification(NOTIFICATIONS.urlRequared);
            error = true;
        }
        if (!this.httpMethod) {
            this.showNotification(NOTIFICATIONS.methodRequared);
            error = true;
        }

        return error;
    }

    // Batches
    async handleOpenRunButchWnd() {
        this.showBatchWnd = true;
        try {
            const data = await getListOfBatches();
            this.batches = data;
        } catch (err) {
            this.showNotification(NOTIFICATIONS.getListBatchesError);
            console.error(err);
        }
    }

    handleSetBatchType(e) {
        this.batchType = e.detail.value;
    }

    handleSetBatchMin(e) {
        this.batchRepeatAfterMin = e.detail.value;
    }

    handleSetRepeatBatch() {
        this.batchRepeat = !this.batchRepeat;
    }

    async handleRunBatch() {
        if (!this.batchType || parseInt(this.batchRepeatAfterMin) < 0) {
            this.showNotification(NOTIFICATIONS.runBatchesValidationError);
            return;
        }
        this.disabledWnd = true;
        try {
            await runBatch({type: this.batchType, min: this.batchRepeatAfterMin, repeat: this.batchRepeat});
            this.batches = await getListOfBatches();
        } catch (e) {
            this.showNotification(NOTIFICATIONS.runBatchesError);
            console.error(err);
        }
        this.disabledWnd = false;
    }

    async handlerDeleteBatch(e) {
        await stopBatch({jobID: e.target.dataset.id});
        this.batches = await getListOfBatches();
    }
}
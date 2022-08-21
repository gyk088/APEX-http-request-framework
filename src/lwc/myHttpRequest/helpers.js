const TABLE_HEADER = [
    {
        key: '_vTableId',
        title: '№',
        width: '7%',
        filter: true,
        sort: true,
    },
    {
        key: 'Url__c',
        title: 'Url',
        width: '28%',
        filter: true,
        sort: true,
    },
    {
        key: 'StatusCode__c',
        title: 'StatusCode',
        width: '10%',
        sort: true,
        filter: true,
    },
    {
        key: 'Method__c',
        title: 'Method',
        width: '10%',
        filter: true,
        sort: true,
    },
    {
        key: 'ClassName__c',
        title: 'ClassName',
        width: '10%',
        filter: true,
        sort: true,
    },
    {
        key: 'StartRepeatDate__c',
        title: 'Date',
        width: '20%',
        filter: false,
        sort: true,
        template: (row) => {
            try {
                const requestDate = new Date(row.Tik__c);
                return `${requestDate.toLocaleDateString()} ${requestDate.toLocaleTimeString()}`;
            } catch (e) {
                return '-';
            }
        }
    },
    {
        key: 'requestTime',
        title: 'Time (sec.)',
        width: '15%',
        sort: false,
        filter: false,
        template: (row) => {
            try {
                const tik = new Date(row.Tik__c);
                const tok = new Date(row.Tok__c);
                return  parseFloat((tok - tik) / 1000).toFixed(2);
            } catch (e) {
                return '-';
            }
        }
    },
];

export const TABLE_CONFIG = {
    rowHeight: 32,
    header: TABLE_HEADER,
    noDataText: 'no data',
    footer: {
        height: 32,
        content: 'No content'
    },
    loading: '<div class="lds-roller"><div></div><div></div><div></div><div></div><div></div><div></div><div></div><div></div></div>',
}

export const WND_CONFIG = {
    createRequest: {
        title: 'Create Http Request',
    },
    repeatRequest: {
        title: 'Repeat Http Request',
    },
    showAllData: {
        title: 'Http Request Data',
    }
}

export const HPPT_METHODS = [
    { value: 'GET', label: 'GET'},
    { value: 'POST', label: 'POST'},
    { value: 'PUT', label: 'PUT'},
    { value: 'PATCH', label: 'PATCH'},
    { value: 'DELETE', label: 'DELETE'},
    { value: 'HEAD', label: 'HEAD'},
]

export const BATCH_TYPES = [
    { value: 'REPEAT', label: 'Rrepeat'},
    { value: 'CLEAR', label: 'Clear'},
    { value: 'CLEARALL', label: 'Clear All'},
]

export const NOTIFICATIONS = {
    urlRequared: {
        variant: 'error',
        title: 'Url is required',
        message: ''
    },
    methodRequared: {
        variant: 'error',
        title: 'Http method is required',
        message: ''
    },
    requestError: {
        variant: 'error',
        title: 'Request not sent',
        mode: 'sticky',
        message: ''
    },
    waiting: {
        variant: 'info',
        title: 'Wait, please',
    },
    requestSuccess: {
        variant: 'success',
        title: 'Request has been sent',
    },
    getListBatchesError: {
        variant: 'error',
        title: 'Error getting list of batches',
    },
    runBatchesError: {
        variant: 'error',
        title: 'Run batch error',
    },
    runBatchesValidationError: {
        variant: 'error',
        title: 'Fill in required fields',
    }
}





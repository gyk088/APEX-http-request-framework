declare module "@salesforce/apex/MyHttpController.getRequests" {
  export default function getRequests(param: {fromDate: any, repeat: any}): Promise<any>;
}
declare module "@salesforce/apex/MyHttpController.sendRequest" {
  export default function sendRequest(param: {jsonData: any}): Promise<any>;
}
declare module "@salesforce/apex/MyHttpController.stopBatch" {
  export default function stopBatch(param: {jobID: any}): Promise<any>;
}
declare module "@salesforce/apex/MyHttpController.runBatch" {
  export default function runBatch(param: {type: any, min: any, repeat: any}): Promise<any>;
}
declare module "@salesforce/apex/MyHttpController.getListOfBatches" {
  export default function getListOfBatches(): Promise<any>;
}

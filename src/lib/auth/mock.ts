export type MockRole="candidate"|"company"|"recruiter"|"admin";
export type MockUser={id:string;email:string;fullName:string;roles:MockRole[]};
export const mockCandidateUser:MockUser={id:"mock-candidate",email:"candidate@example.test",fullName:"Mock Candidate",roles:["candidate"]};
export const mockCompanyUser:MockUser={id:"mock-company",email:"company@example.test",fullName:"Mock Company",roles:["company"]};
export const mockRecruiterUser:MockUser={id:"mock-recruiter",email:"recruiter@example.test",fullName:"Mock Recruiter",roles:["recruiter"]};
export const mockAdminUser:MockUser={id:"mock-admin",email:"admin@example.test",fullName:"Mock Admin",roles:["admin"]};
export const mockUsers=[mockCandidateUser,mockCompanyUser,mockRecruiterUser,mockAdminUser];
export const isMockAuthEnabled=()=>process.env.NEXT_PUBLIC_MOCK_AUTH==="true"&&process.env.NODE_ENV!=="production";
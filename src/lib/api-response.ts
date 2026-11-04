import { NextResponse } from "next/server";
export type ApiErrorCode="VALIDATION_ERROR"|"UNAUTHENTICATED"|"FORBIDDEN"|"NOT_FOUND"|"RATE_LIMITED"|"CONFLICT"|"INTERNAL_ERROR";
export function success<T>(data:T,status=200){return NextResponse.json({success:true,data,error:null},{status});}
export function failure(code:ApiErrorCode,message:string,status:number,details?:unknown){return NextResponse.json({success:false,data:null,error:{code,message,...(details?{details}:{})}},{status});}
export function validationFailure(error:{issues:unknown}){return failure("VALIDATION_ERROR","البيانات المدخلة غير صحيحة.",400,error.issues);}
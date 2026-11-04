import "server-only";
import { createHmac } from "node:crypto";
import { isIP } from "node:net";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
type AttemptResult={allowed:boolean;attempt_id:number|null;retry_after_seconds:number};
type RpcClient={rpc:(name:string,args:Record<string,unknown>)=>Promise<{data:unknown;error:{message:string}|null}>};
function secret(){const value=process.env.AUTH_RATE_LIMIT_SECRET;if(!value||value.length<32)throw new Error("AUTH_RATE_LIMIT_SECRET must contain at least 32 characters.");return value;}
function fingerprint(value:string){return createHmac("sha256",secret()).update(value).digest("hex");}
function adminClient():RpcClient{const url=process.env.NEXT_PUBLIC_SUPABASE_URL;const key=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!url||!key)throw new Error("Server-side Supabase service role configuration is missing.");return createSupabaseClient(url,key,{auth:{autoRefreshToken:false,persistSession:false,detectSessionInUrl:false}}) as unknown as RpcClient;}
export async function beginLoginAttempt(email:string,request:Request){const normalized=email.trim().toLowerCase();const rawIp=request.headers.get("x-real-ip")??"";const ip=isIP(rawIp)?rawIp:"";const identifierHash=fingerprint("login:"+normalized);const ipHash=fingerprint(ip?"ip:"+ip:"no-trusted-ip:"+normalized);const result=await adminClient().rpc("begin_auth_attempt",{p_identifier_hash:identifierHash,p_ip_hash:ipHash,p_ip_address:ip||null,p_user_agent:request.headers.get("user-agent")?.slice(0,1000)??null});if(result.error)throw new Error("Rate limit service unavailable.");const row=Array.isArray(result.data)?result.data[0] as AttemptResult|undefined:undefined;if(!row)throw new Error("Rate limit service returned an invalid response.");return row;}
export async function completeSuccessfulLogin(attemptId:number,userId:string){const result=await adminClient().rpc("complete_auth_attempt",{p_attempt_id:attemptId,p_user_id:userId});if(result.error||result.data!==true)throw new Error("Could not finalize authentication attempt.");}

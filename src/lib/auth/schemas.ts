import {z} from "zod";
export const emailSchema=z.string().trim().email().max(254);
export const passwordSchema=z.string().min(10).max(128);
export const registerSchema=z.object({email:emailSchema,password:passwordSchema,fullName:z.string().trim().min(2).max(120)});
export const loginSchema=z.object({email:emailSchema,password:z.string().min(1).max(128)});
export const forgotPasswordSchema=z.object({email:emailSchema});
export const resetPasswordSchema=z.object({password:passwordSchema});
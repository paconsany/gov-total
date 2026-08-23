export type PublicationStatus='Rascunho'|'Agendado'|'Publicado'
export type News={id:number;title:string;subtitle:string;content:string;department:string;author:string;cover:string;date:string;status:PublicationStatus;slug:string}
export type PortalPage={id:number;title:string;slug:string;content:string;status:PublicationStatus}
export type PortalDocument={id:number;title:string;slug?:string;summary?:string;category:string;description:string;date:string;file:string;status:PublicationStatus}
export type Legislation={id:number;title?:string;type:string;number:string;year:string;summary:string;date:string;content:string;status:PublicationStatus}
export type Department={id:number;name:string;head:string;description:string;phone:string;email:string;address:string;hours:string}
export type Banner={id:number;title:string;image:string;link:string;order:number;active:boolean}
export type AgendaEvent={id:number;event:string;date:string;time:string;place:string;description:string;status:PublicationStatus}
export type QuickLink={id:number;label:string;target:string;active:boolean;external:boolean}
export type ExternalLink={id:number;label:string;url:string}
export type PortalState={news:News[];pages:PortalPage[];documents:PortalDocument[];legislation:Legislation[];departments:Department[];banners:Banner[];agenda:AgendaEvent[];quickLinks:QuickLink[];externalLinks:ExternalLink[];menuOrder:string[]}
export const slugify=(text:string)=>text.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().trim().replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,'')
export const isSlugUnique=<T extends {id:number;slug?:string}>(items:T[],slug:string,currentId=0)=>Boolean(slug)&&!items.some(item=>item.id!==currentId&&item.slug===slug)
export const findBySlug=<T extends {slug?:string}>(items:T[],slug:string)=>items.find(item=>item.slug===slug)
export const contentPath=(type:'noticias'|'paginas'|'documentos',slug:string)=>`/${type}/${slug}`

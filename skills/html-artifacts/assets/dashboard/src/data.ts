export type LogEvent={id:string;time:number;status:'INFO'|'WARN'|'ERROR'|'DEBUG';service:string;env:string;host:string;message:string;pattern:string;duration:number;trace:string;path:string;code:number;region:string};
export const services=['api-gateway','checkout','catalog','payments','worker','auth'];
export const captureEnd=Date.UTC(2026,8,10,15,0,0);
let seed=91821,serial=0;
const random=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296};
export function makeEvent(time:number,live=false):LogEvent{
 const service=services[Math.floor(random()*services.length)],env=random()<.87?'prod':'staging';
 const incident=time>=captureEnd-18*60000&&time<captureEnd-14*60000;
 const p=random(),status=p<(incident&&service==='checkout'?.48:.023)?'ERROR':p<.12?'WARN':p<.2?'DEBUG':'INFO';
 const patterns=service==='checkout'?['order.completed','cart.loaded','inventory.reserved']:service==='worker'?['job.completed','batch.processed','queue.polled']:service==='auth'?['session.validated','token.refreshed','policy.evaluated']:['request.completed','cache.hit','upstream.responded'];
 const pattern=status==='ERROR'?(service==='checkout'?'redis.timeout':'upstream.failure'):status==='WARN'?'request.slow':patterns[Math.floor(random()*patterns.length)];
 const duration=pattern==='redis.timeout'?Math.round(900+random()*1200):status==='ERROR'?Math.round(450+random()*1100):status==='WARN'?Math.round(280+random()*650):Math.round(8+Math.pow(random(),3)*230);
 const path=service==='checkout'?'/v1/checkout':service==='auth'?'/v1/session':service==='worker'?'/jobs/dispatch':'/v1/'+service.split('-')[0];
 const id='evt_'+String(++serial).padStart(6,'0'),trace=Math.floor(random()*0xffffffff).toString(16).padStart(8,'0')+Math.floor(random()*0xffffffff).toString(16).padStart(8,'0');
 const message=pattern==='redis.timeout'?'Redis command timed out while reserving inventory':pattern==='upstream.failure'?'Upstream returned 503; retry budget exhausted':pattern==='request.slow'?`Slow request ${path}; exceeded 250 ms budget`:pattern==='cache.hit'?`Cache hit for ${path}`:pattern==='job.completed'?'Background job completed; batch committed':`${pattern.replaceAll('.',' ')} ${path}`;
 return {id,time,status,service,env,host:service+'-'+String(1+Math.floor(random()*4)).padStart(2,'0'),message,pattern,duration,trace,path,code:status==='ERROR'?503:200,region:random()<.68?'us-east-1':'eu-west-1'};
}
export function initialEvents(){const result:LogEvent[]=[];for(let minute=0;minute<30;minute++){const count=280+Math.round(random()*130)+(minute>=12&&minute<=15?180:0);for(let i=0;i<count;i++)result.push(makeEvent(captureEnd-(30-minute)*60000+Math.floor(random()*60000)))}return result.sort((a,b)=>b.time-a.time)}
export function timeLabel(time:number,seconds=false){return new Date(time).toISOString().slice(11,seconds?19:16)}
export function p95(rows:LogEvent[]){if(!rows.length)return 0;const a=rows.map(r=>r.duration).sort((a,b)=>a-b);return a[Math.ceil(a.length*.95)-1]}
export function compileQuery(query:string):(r:LogEvent)=>boolean{
 const tokens=query.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g)||[];
 if((query.match(/"/g)||[]).length%2)throw Error('Close the quoted search phrase.');
 const tests=tokens.map(token=>{
  const duration=token.match(/^duration:(>|>=|<|<=)(\d+)$/);if(duration){const n=Number(duration[2]);return (r:LogEvent)=>duration[1]==='>'?r.duration>n:duration[1]==='>='?r.duration>=n:duration[1]==='<'?r.duration<n:r.duration<=n}
  const pair=token.match(/^([a-z]+):(.*)$/i);if(pair){let [,key,value]=pair;key=key==='severity'?'status':key;if(!['service','status','env','host','trace','pattern'].includes(key))throw Error(`Unknown field “${key}”. Use service, status, env, host, trace, pattern, or duration:>500.`);value=value.replace(/^['"]|['"]$/g,'').toLowerCase();if(!value)throw Error(`Add a value after ${key}:`);return (r:LogEvent)=>String(r[key as keyof LogEvent]).toLowerCase()===value}
  const needle=token.replace(/^['"]|['"]$/g,'').toLowerCase();return (r:LogEvent)=>(r.message+' '+r.service+' '+r.pattern+' '+r.trace).toLowerCase().includes(needle);
 });return r=>tests.every(fn=>fn(r));
}

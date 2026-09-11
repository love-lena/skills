(() => {
 const svg=document.querySelector('.architecture-graph');if(!svg)return;
 const ns='http://www.w3.org/2000/svg',root=svg.querySelector('[data-architecture-layers]');
 function el(tag,attrs={},text='',parent=root){const n=document.createElementNS(ns,tag);Object.entries(attrs).forEach(([k,v])=>n.setAttribute(k,v));if(text)n.textContent=text;parent.append(n);return n}
 const defs=el('defs');const marker=el('marker',{id:'architecture-arrow',viewBox:'0 0 10 10',refX:9,refY:5,markerWidth:6,markerHeight:6,orient:'auto-start-reverse'},'',defs);el('path',{d:'M 0 0 L 10 5 L 0 10 Z',fill:'context-stroke'},'',marker);
 [[8,128,'01  SOURCES'],[150,352,'02  PREPARE'],[384,620,'03  BUILD'],[650,886,'04  CHECKS'],[934,1048,'05  DELIVER']].forEach(([y,end,label])=>{el('rect',{x:36,y,width:808,height:end-y,rx:9,class:'graph-group'});el('text',{x:50,y:y+23,class:'graph-group-title'},label)});
 const nodes=[
 ['docs',48,52,'Markdown documents','Selected text','Authoritative text selected for this pack. The snapshot pins the exact revision.'],
 ['diagrams',337,52,'Diagram sources','Editable definitions','Editable diagram definitions travel with the same snapshot as their surrounding text.'],
 ['attachments',626,52,'Attachments','Required resources','Images and other required reading resources must be present before assembly.'],
 ['snapshot',337,188,'Source snapshot','Pin source versions','Collects all three source types at known versions. Changes after this point require a new snapshot.'],
 ['manifest',337,276,'Manifest','Inputs + build identity','Records pinned source versions, required resources, and build identity. Findings trigger a revision here before another attempt.'],
 ['text',48,416,'Text builder','Structured content','Transforms the manifest’s pinned documents into structured HTML. Runs alongside diagram and asset work.'],
 ['render',337,416,'Diagram renderer','Embedded SVG','Renders the pinned diagrams into accessible, embedded SVG. Its output joins text and assets at the assembler.'],
 ['assets',626,416,'Asset packager','Local resources','Embeds required resources so the finished pack can be read offline. Missing inputs stop the attempt.'],
 ['assembler',337,542,'HTML assembler','One candidate file','Waits for all three build outputs and combines them into one candidate file with styles and provenance.'],
 ['offline',48,682,'Offline check','Required resources','Checks required resources with network access unavailable. Optional external references are explicitly labelled.'],
 ['contrast',337,682,'Contrast check','Light + dark','Checks text and diagram contrast in both appearances. Its result is one of three required release inputs.'],
 ['links',626,682,'Link check','Targets + references','Checks internal targets and required references. Optional external links remain visibly identified.'],
 ['gate',337,808,'Release gate','Require all checks','Waits for every check. Passing produces a pack; a failure or missing result produces findings. No partial release.'],
 ['findings',48,966,'Findings report','Failed or incomplete','Describes failed or missing checks and routes the attempt back to the manifest for revision and retry.'],
 ['pack',337,966,'Reading pack','Validated snapshot','A self-contained HTML snapshot with source versions and generation date. Later source edits do not change it.'],
 ['reader',626,966,'Reader','Offline access','Reads the validated snapshot without needing its source workspace. Optional external links still need connectivity.']
 ];
 const edges=[];
 function edge(from,to,d,label,x,y,feedback=false){const path=el('path',{d,class:'graph-edge'+(feedback?' feedback':''),'marker-end':'url(#architecture-arrow)'});let caption;if(label)caption=el('text',{x,y,'text-anchor':'middle',class:'graph-edge-label'},label);edges.push({from,to,path,caption})}
 edge('docs','snapshot','M151 108 V140 H440 V188');edge('diagrams','snapshot','M440 108 V188','capture',478,132);edge('attachments','snapshot','M729 108 V140 H440 V188');
 edge('snapshot','manifest','M440 244 V276','record',478,263);
 edge('manifest','text','M440 332 V366 H151 V416','pinned inputs',236,370);edge('manifest','render','M440 332 V416');edge('manifest','assets','M440 332 V366 H729 V416');
 edge('text','assembler','M151 472 V510 H440 V542','HTML',151,497);edge('render','assembler','M440 472 V542','SVG',469,498);edge('assets','assembler','M729 472 V510 H440 V542','assets',729,497);
 edge('assembler','offline','M440 598 V636 H151 V682','candidate file',236,639);edge('assembler','contrast','M440 598 V682');edge('assembler','links','M440 598 V636 H729 V682');
 edge('offline','gate','M151 738 V775 H440 V808','result',151,761);edge('contrast','gate','M440 738 V808','result',471,761);edge('links','gate','M729 738 V775 H440 V808','result',729,761);
 edge('gate','findings','M440 864 V914 H151 V966','any failure / incomplete',235,910);edge('gate','pack','M440 864 V966','all pass',476,937);edge('pack','reader','M543 994 H626','deliver',584,983);
 edge('findings','manifest','M48 994 H22 V304 H337','revise & retry',173,296,true);
 const nodeEls=new Map();nodes.forEach(([id,x,y,title,detail])=>{const g=el('g',{class:'graph-node',tabindex:0,role:'button','aria-label':title+' — '+detail,'aria-pressed':'false','data-node':id});el('rect',{x,y,width:206,height:56,rx:6},'',g);el('text',{x:x+103,y:y+24,'text-anchor':'middle',class:'node-title'},title,g);el('text',{x:x+103,y:y+43,'text-anchor':'middle',class:'node-detail'},detail,g);g.addEventListener('click',()=>select(id));g.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();select(id)}});nodeEls.set(id,g)});
 const clear=document.querySelector('[data-clear-node]');
 function select(id){const related=new Set([id]);edges.forEach(e=>{const active=e.from===id||e.to===id;if(active){related.add(e.from);related.add(e.to)}e.path.classList.toggle('highlight',!!id&&active);e.path.classList.toggle('graph-dim',!!id&&!active);e.caption?.classList.toggle('graph-dim',!!id&&!active)});nodeEls.forEach((g,key)=>{g.classList.toggle('selected',key===id);g.classList.toggle('graph-dim',!!id&&!related.has(key));g.setAttribute('aria-pressed',key===id)});const n=nodes.find(n=>n[0]===id);document.querySelector('[data-node-title]').textContent=n?n[3]:'Read top to bottom, follow one branch at a time';document.querySelector('[data-node-description]').textContent=n?n[5]:'Select a component to highlight its immediate connections. Stage headings help you keep your place; Fit brings the whole graph back into view.';clear.hidden=!id}
 clear.addEventListener('click',()=>{const selected=svg.querySelector('.selected');select(null);selected?.focus()});
 const viewport=document.querySelector('.graph-viewport');
 let zoom=viewport.clientWidth>=590?Math.min(1,viewport.clientWidth/880):1,fit=false;
 let panX=(viewport.clientWidth-880*zoom)/2,panY=0;
 function renderPan(){svg.style.transform=`translate(${panX}px, ${panY}px)`}
 function renderZoom(){svg.style.width=(880*zoom)+'px';renderPan();document.querySelector('[data-zoom-label]').textContent=Math.round(zoom*100)+'%'}
 function fitGraph(){zoom=Math.min(viewport.clientWidth/880,viewport.clientHeight/1080);panX=(viewport.clientWidth-880*zoom)/2;panY=(viewport.clientHeight-1080*zoom)/2;renderZoom()}
 document.querySelectorAll('[data-zoom]').forEach(b=>b.addEventListener('click',()=>{
  fit=b.dataset.zoom==='fit';if(fit){fitGraph();return}
  const previous=zoom;zoom=Math.max(.25,Math.min(2,zoom+(b.dataset.zoom==='in'?.2:-.2)));
  const cx=viewport.clientWidth/2,cy=viewport.clientHeight/2;
  panX=cx-(cx-panX)*zoom/previous;panY=cy-(cy-panY)*zoom/previous;renderZoom();
 }));
 // A short movement is a click; a drag moves the canvas, including from a node.
 let pointer=null,suppressClick=false;
 viewport.addEventListener('pointerdown',e=>{
  if(!e.isPrimary||e.button!==0)return;
  suppressClick=false;pointer={id:e.pointerId,x:e.clientX,y:e.clientY,panX,panY,dragging:false};
 });
 viewport.addEventListener('pointermove',e=>{
  if(!pointer||pointer.id!==e.pointerId)return;
  const dx=e.clientX-pointer.x,dy=e.clientY-pointer.y;
  if(!pointer.dragging&&Math.hypot(dx,dy)<5)return;
  if(!pointer.dragging){pointer.dragging=true;viewport.setPointerCapture(e.pointerId);viewport.classList.add('is-dragging')}
  fit=false;panX=pointer.panX+dx;panY=pointer.panY+dy;renderPan();e.preventDefault();
 });
 function endDrag(e){if(!pointer||pointer.id!==e.pointerId)return;suppressClick=pointer.dragging;pointer=null;viewport.classList.remove('is-dragging');if(viewport.hasPointerCapture(e.pointerId))viewport.releasePointerCapture(e.pointerId)}
 viewport.addEventListener('pointerup',endDrag);viewport.addEventListener('pointercancel',endDrag);viewport.addEventListener('lostpointercapture',endDrag);
 viewport.addEventListener('click',e=>{if(suppressClick&&e.detail!==0){e.preventDefault();e.stopImmediatePropagation();suppressClick=false}},true);
 viewport.addEventListener('keydown',e=>{
  const directions={ArrowLeft:[48,0],ArrowRight:[-48,0],ArrowUp:[0,48],ArrowDown:[0,-48]};
  if(!directions[e.key]||e.altKey||e.metaKey||e.ctrlKey)return;
  e.preventDefault();fit=false;panX+=directions[e.key][0];panY+=directions[e.key][1];renderPan();
 });
 // Bring keyboard-focused nodes into view after a pan or a zoom.
 svg.addEventListener('focusin',e=>{
  const node=e.target.closest('[data-node]');if(!node)return;
  const box=node.getBoundingClientRect(),frame=viewport.getBoundingClientRect();
  if(box.left<frame.left||box.right>frame.right||box.top<frame.top||box.bottom>frame.bottom){panX+=frame.left+frame.width/2-(box.left+box.width/2);panY+=frame.top+frame.height/2-(box.top+box.height/2);fit=false;renderPan()}
 });
 let previousWidth=viewport.clientWidth;
 const resize=new ResizeObserver(()=>{if(fit)fitGraph();else{panX+=(viewport.clientWidth-previousWidth)/2;renderPan()}previousWidth=viewport.clientWidth});resize.observe(viewport);
 const shell=document.querySelector('.graph-shell'),expand=document.querySelector('[data-expand]'),placeholder=document.createComment('graph position');shell.before(placeholder);const dialog=document.createElement('dialog');dialog.className='graph-dialog';dialog.setAttribute('aria-label','Expanded architecture graph');document.body.append(dialog);
 function restore(){placeholder.after(shell);expand.textContent='Expand';expand.focus()}
 dialog.addEventListener('close',restore);expand.addEventListener('click',()=>{if(dialog.open){dialog.close()}else{dialog.append(shell);expand.textContent='Close';dialog.showModal();expand.focus()}});
 renderZoom();
})();

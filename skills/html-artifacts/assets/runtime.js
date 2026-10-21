(() => {
  const params=new URLSearchParams(location.search);
  const appearance=document.querySelector('[data-control="appearance"]');
  const width=document.querySelector('[data-control="width"]');
  const shape=document.querySelector('[data-control="shape"]');
  if(appearance&&['system','light','dark'].includes(params.get('appearance')))appearance.value=params.get('appearance');
  if(width&&params.get('width')==='mobile')width.value='mobile';
  function apply() {
    const mode=appearance?.value||'system';
    document.documentElement.style.colorScheme=mode==='system'?'light dark':mode;
    document.querySelector('.page')?.classList.toggle('mobile',width?.value==='mobile');
    // Standalone files also work without origin-dependent history or storage APIs.
    if(location.protocol==='http:'||location.protocol==='https:'){
      const url=new URL(location.href);url.searchParams.set('appearance',mode);
      if(width)url.searchParams.set('width',width.value);
      history.replaceState(null,'',url);
    }
  }
  appearance?.addEventListener('change',apply);width?.addEventListener('change',apply);
  shape?.addEventListener('change',()=>{
    const url=new URL(shape.value,location.href);url.searchParams.set('appearance',appearance?.value||'system');url.searchParams.set('width',width?.value||'desktop');location.href=url;
  });
  apply();
  const ns='http://www.w3.org/2000/svg';
  document.querySelectorAll('svg[data-flow]').forEach(svg=> {
    const model=JSON.parse(svg.dataset.flow);
    const g=svg.querySelector('g');
    function el(tag,attributes,text) {
      const node=document.createElementNS(ns,tag);
      for(const [key,value] of Object.entries(attributes))node.setAttribute(key,value);
      if(text)node.textContent=text;
      g.append(node);
    }
    function box(x,y,w,node) {
      el('rect',{x,y,width:w,height:76,rx:7});
      el('text',{x:x+w/2,y:y+29,'text-anchor':'middle',class:'node-title'},node[0]);
      el('text',{x:x+w/2,y:y+52,'text-anchor':'middle',class:'node-detail'},node[1]);
    }
    function draw() {
      const w=Math.round(svg.getBoundingClientRect().width);
      if(!w)return;
      g.replaceChildren();
      if(w>=590 && model.nodes.length===3) {
        const gap=68,bw=(w-2-gap*2)/3;
        svg.setAttribute('viewBox',`0 0 ${w} 134`);
        model.nodes.forEach((node,i)=>box(1+i*(bw+gap),18,bw,node));
        model.edges.forEach((label,i)=> {
          const x=1+(i+1)*bw+i*gap,end=x+gap;
          el('path',{d:`M ${x} 56 H ${end-6}`,class:'edge'});
          el('path',{d:`M ${end-6} 52 L ${end} 56 L ${end-6} 60 Z`,class:'arrow'});
          el('text',{x:x+gap/2,y:84,'text-anchor':'middle',class:'edge-label'},label);
        });
      } else {
        const bw=Math.min(w-2,330),x=(w-bw)/2,step=126;
        svg.setAttribute('viewBox',`0 0 ${w} ${step*(model.nodes.length-1)+78}`);
        model.nodes.forEach((node,i)=>box(x,1+i*step,bw,node));
        model.edges.forEach((label,i)=> {
          const y=77+i*step,end=1+(i+1)*step;
          el('path',{d:`M ${w/2} ${y} V ${end-6}`,class:'edge'});
          el('path',{d:`M ${w/2-4} ${end-6} L ${w/2} ${end} L ${w/2+4} ${end-6} Z`,class:'arrow'});
          el('text',{x:w/2+14,y:y+29,class:'edge-label'},label);
        });
      }
    }
    new ResizeObserver(draw).observe(svg);draw();
  });
})();

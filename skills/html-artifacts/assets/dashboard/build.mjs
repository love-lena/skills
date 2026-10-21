import {build} from 'esbuild';
await build({absWorkingDir:import.meta.dirname,entryPoints:['src/App.tsx'],bundle:true,minify:true,format:'iife',outfile:'dist/app.js',jsx:'automatic',define:{'process.env.NODE_ENV':'"production"'},legalComments:'eof'});

import {readFile,appendFile} from "node:fs/promises";
const license=await readFile(new URL("./SHADCN-LICENSE.md",import.meta.url),"utf8");
await appendFile(new URL("./dist/app.js",import.meta.url),"\n/*! shadcn/ui\n"+license.replaceAll("*/","* /")+"\n*/\n");

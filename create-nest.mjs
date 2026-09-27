#!/usr/bin/env node
//
// (c) https://dev.to/micalevisk/5-steps-to-create-a-bare-minimum-nestjs-app-from-scratch-5c3b
//
// Written in Node.js rather than Bash so that this `bin` runs on every platform
// the package managers do. The generated Windows shim used to hand a Win32 path
// to whatever `bash` was on PATH, which breaks when that is WSL's `bash.exe`.
// See https://github.com/micalevisk/create-nest/issues/3
//

import { spawnSync } from 'node:child_process'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, resolve } from 'node:path'
import process from 'node:process'

const app_dir = process.argv[2] || 'nestjs-app'

if (!app_dir.trim()) process.exit(1)

const target_dir = resolve(app_dir)
mkdirSync(target_dir, { recursive: true })

/** Runs a command inside the generated app directory, inheriting our stdio.
 *  `shell: true` is what makes `npm`/`pnpm`/`yarn`/`npx` resolvable on Windows,
 *  where they are `.cmd` shims that cannot be spawned directly. Every command
 *  below is built from literals only, so there is nothing to escape here. */
function run(command) {
  const { status, error } = spawnSync(command, {
    cwd: target_dir,
    stdio: 'inherit',
    shell: true,
  })
  if (error) throw error
  if (status !== 0) process.exit(status ?? 1)
}

function write(file, contents) {
  writeFileSync(join(target_dir, file), contents)
}

// Using NPM as the default package manager if we did not succeed on inferring the invoked one
function inferPackageManager() {
  // Every package manager sets this when it runs a `create-*` package.
  const [name] = (process.env.npm_config_user_agent ?? '').split('/')
  if (name === 'npm' || name === 'pnpm' || name === 'yarn') return name

  // Fall back to sniffing the paths we were invoked through, like the previous
  // shell implementation did.
  const invoked_through = `${process.env.npm_execpath ?? ''} ${process.argv[1] ?? ''}`
  if (invoked_through.includes('pnpm')) return 'pnpm'
  if (invoked_through.includes('yarn')) return 'yarn'
  return 'npm'
}

const package_manager = inferPackageManager()

console.log(`Using ${package_manager} as the package manager!`)

const dependencies = [
  'reflect-metadata@latest',
  '@nestjs/common@latest',
  '@nestjs/core@latest',
  '@nestjs/platform-express@latest',
]
const dev_dependencies = [
  'typescript@6',
  '@types/node',
  '@nestjs/cli@latest',
  '@nestjs/schematics@latest',
]

switch (package_manager) {
  case 'pnpm':
    run('pnpm init')
    run(`pnpm install ${dependencies.join(' ')}`)
    run(`pnpm install --save-dev ${dev_dependencies.join(' ')}`)
    break

  case 'npm':
    run('npm init --yes')
    run(`npm install ${dependencies.join(' ')}`)
    run(`npm install --save-dev ${dev_dependencies.join(' ')}`)
    break

  case 'yarn':
    run('yarn init --yes')
    run(`yarn add ${dependencies.join(' ')}`)
    run(`yarn add --save-dev ${dev_dependencies.join(' ')}`)
    break
}

// Patching `package.json` in place instead of shelling out to `npm pkg`, so we
// don't depend on npm being installed when pnpm or yarn was the one invoked.
const package_json_path = join(target_dir, 'package.json')
const package_json = JSON.parse(readFileSync(package_json_path, 'utf8'))
delete package_json.scripts?.test
package_json.main = 'dist/src/main'
package_json.scripts = {
  ...package_json.scripts,
  build: 'nest build',
  'start:dev': 'nest start --watch',
  'start:prod': 'node .',
}
writeFileSync(package_json_path, `${JSON.stringify(package_json, null, 2)}\n`)

mkdirSync(join(target_dir, 'src'), { recursive: true })
write('tsconfig.json', `{
  "compilerOptions": {
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "resolvePackageJsonExports": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2023",
    "sourceMap": true,
    "outDir": "./dist",
    "incremental": true,
    "skipLibCheck": true,
    "strict": true,
    "strictPropertyInitialization": false,
    "types": ["node"]
  }
}
`)
write('tsconfig.build.json', `{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "rootDir": "./src"
  },
  "include": ["src"],
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
`)
write('nest-cli.json', `{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "monorepo": false,
  "sourceRoot": "src",
  "entryFile": "main",
  "language": "ts",
  "generateOptions": {
    "spec": true
  },
  "compilerOptions": {
    "tsConfigPath": "./tsconfig.build.json",
    "deleteOutDir": true,
    "assets": [],
    "watchAssets": false,
    "plugins": []
  }
}
`)

run('npx nest generate module app --flat')
write('src/main.ts', `import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  await app.listen(process.env.PORT || 3000);
}
bootstrap();
`)

write('.gitignore', `dist/
node_modules/
[._]*.s[a-v][a-z]
[._]*.sw[a-p]
[._]s[a-rt-v][a-z]
[._]ss[a-gi-z]
[._]sw[a-p]

`)

console.log(`\nApp created at '${app_dir}' directory!`)

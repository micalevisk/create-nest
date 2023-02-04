#!/usr/bin/env bash
#
# (c) https://dev.to/micalevisk/5-steps-to-create-a-bare-minimum-nestjs-app-from-scratch-5c3b
# This requires NPM v9+ and npx(1) v9+
#

mkdir ${1:-"nestjs-app"}
cd $_
npm init --yes

npm install reflect-metadata@latest @nestjs/common@latest @nestjs/core@latest
npm i @nestjs/platform-express@latest
npm i -D typescript@^4 @types/node @nestjs/cli@latest @nestjs/schematics@latest

npm pkg delete scripts.test
npm pkg set main="dist/src/main"
npm pkg set scripts.build="nest build"
npm pkg set scripts.start:dev="nest start --watch"
npm pkg set scripts.start:prod="node ."

mkdir src
cat <<EOF > tsconfig.json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2021",
    "strictNullChecks": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./",
    "baseUrl": "./",
    "skipLibCheck": true,
    "incremental": true
  }
}
EOF
cat <<EOF > tsconfig.build.json
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
EOF
cat <<EOF > nest-cli.json
{
  "\$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "monorepo": false,
  "sourceRoot": "src",
  "entryFile": "main",
  "language": "ts",
  "generateOptions": {
    "spec": false
  },
  "compilerOptions": {
    "tsConfigPath": "./tsconfig.build.json",
    "webpack": false,
    "deleteOutDir": true,
    "assets": [],
    "watchAssets": false,
    "plugins": []
  }
}
EOF

npx nest generate module app --flat
cat <<EOF > src/main.ts
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  await app.listen(process.env.PORT || 3000);
}
bootstrap();
EOF

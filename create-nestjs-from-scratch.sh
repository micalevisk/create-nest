#!/usr/bin/env bash
#
# (c) https://dev.to/micalevisk/5-steps-to-create-a-bare-minimum-nestjs-app-from-scratch-5c3b
#

app_dir=${1:-"nestjs-app"}

[ -z "$app_dir" ] && exit 1

mkdir $app_dir
cd $app_dir


## Using NPM as the default package manager if we didn't succeeded on inferring the invoked one
package_manager="npm"
case "$0" in
  *pnpm*)
    package_manager="pnpm"
    ;;

  *npm*)
    package_manager="npm"
    ;;

  *yarn*)
    package_manager="yarn"
    ;;
esac

echo "Using $package_manager as the package manager!"

case "$package_manager" in
  *pnpm*)
    pnpm init
    pnpm install reflect-metadata@latest @nestjs/common@latest @nestjs/core@latest @nestjs/platform-express@latest
    pnpm install --save-dev typescript@6 @types/node @nestjs/cli@latest @nestjs/schematics@latest

    ;;

  *npm*)
    npm init --yes
    npm install reflect-metadata@latest @nestjs/common@latest @nestjs/core@latest @nestjs/platform-express@latest
    npm install --save-dev typescript@6 @types/node @nestjs/cli@latest @nestjs/schematics@latest

    ;;

  *yarn*)
    yarn init --yes
    yarn add reflect-metadata@latest @nestjs/common@latest @nestjs/core@latest @nestjs/platform-express@latest
    yarn add --save-dev typescript@6 @types/node @nestjs/cli@latest @nestjs/schematics@latest
    ;;
esac


npm pkg delete scripts.test
npm pkg set main="dist/src/main"
npm pkg set scripts.build="nest build"
npm pkg set scripts.start:dev="nest start --watch"
npm pkg set scripts.start:prod="node ."

mkdir src
cat <<EOF > tsconfig.json
{
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
EOF
cat <<EOF > tsconfig.build.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "rootDir": "./src"
  },
  "include": ["src"],
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

cat <<EOF > .gitignore
dist/
node_modules/
[._]*.s[a-v][a-z]
[._]*.sw[a-p]
[._]s[a-rt-v][a-z]
[._]ss[a-gi-z]
[._]sw[a-p]

EOF


echo -e "\nApp created at '$app_dir' directory!"

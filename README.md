# Webpacker::Remote

![](https://github.com/lunatic-cat/webpacker-remote/workflows/ci/badge.svg)
[![Gem Version](https://badge.fury.io/rb/webpacker-remote.svg)](https://badge.fury.io/rb/webpacker-remote)
[![codecov](https://codecov.io/gh/lunatic-cat/webpacker-remote/branch/master/graph/badge.svg?token=X5K67X3V0Z)](undefined)

- support for `create-react-app` developed in a separate repo
- support for multiple external frontend builds, right now `webpacker` is [a singleton](https://github.com/rails/webpacker/blob/6ba995aed2b609a27e4e35ec28b2a7f688cce0cf/lib/webpacker/helper.rb#L5L7)

## Usage

- build `webpack` bundle & upload `build` directory (incl. `manifest.json`) before deploy
- in `config/initializers/remote_webpacker.rb`

```rb
REMOTE_WEBPACKER = Webpacker::Remote.new(root_path: 'https://asset_host/build/', config_path: 'manifest.json')
```

- in `app/views/layouts/application.html.erb` (**not** `javascript_pack_tag`)

```rb
<%= javascript_packs_with_chunks_tag 'main', webpacker: REMOTE_WEBPACKER %>
#=> <script src='https://asset_host/build/static/js/main.2e302672.chunk.js'>
```

Of course, you can use as many build as you like and do blue-green deployments using gems like `rollout`

## CRA Requirements

For `create-react-app` you should use `webpack-assets-manifest` instead of built-in `webpack-manifest-plugin`. You have to patch configuration like this:

- in `package.json`

```diff
+    "customize-cra": "^1.0.0",
+    "react-app-rewired": "^2.1.8"
+    "webpack-assets-manifest": "^3.1.1"
...
-    "build": "react-scripts build"
+    "build": "react-app-rewired build"
```

- add `config-overrides.js`

```js
const { override } = require("customize-cra");
const WebpackAssetsManifest = require('webpack-assets-manifest')

const whenInMode = (mode, fn) => config => (config.mode == mode) ? fn(config) : config;

const removeWebpackPlugin = pluginName => config => {
  config.plugins = config.plugins.filter(
    p => p.constructor.name !== pluginName
  );
  return config;
};

const addWebpackPlugin = plugin => config => {
  config.plugins.push(plugin);
  return config;
};

const webpackerAssetManifestConfig = {
  integrity: false,
  entrypoints: true,
  writeToDisk: true,
  output: 'manifest.json'
};

module.exports = override(
  removeWebpackPlugin('ManifestPlugin'),
  whenInMode('production', addWebpackPlugin(new WebpackAssetsManifest(webpackerAssetManifestConfig)))
);
```

- check `PUBLIC_URL='https://...' npm run build` and `build/manifest.json` should look like this:

```json
{
  "entrypoints": {
    "main": {
      "js": [
        "static/js/runtime-main...js",
        "static/js/2...chunk.js",
        "static/js/main...chunk.js"
      ],
      "js.map": [
        "static/js/runtime-main...js.map",
        "static/js/2...chunk.js.map",
        "static/js/main...chunk.js.map"
      ],
      "css": [
        "static/css/2...chunk.css",
        "static/css/main...chunk.css"
      ]
    }
  },
  "main.css": "static/css/main...chunk.css",
  "main.js": "static/js/main...chunk.js",
  "main.js.map": "static/js/main...chunk.js.map",
  "runtime-main.js": "static/js/runtime-main...js",
  "runtime-main.js.map": "static/js/runtime-main...js.map"
}
```
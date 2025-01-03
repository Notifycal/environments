# Service Registration / Service Discovery

## Registration

We're using a simple approach where each stack will register itself if required. This is configurable with a boolean `register` flag in `stacks/<stack>/source.json`.

The registration is against SSM, using a parameter name/key of the following shape:
```
/notifycal/<environment>/<stack>/url
```

## Discovery

As this applies mostly (uniquely?) to SPAs, each SPA will need to define a `config.skel.js` file:

Example `.skel.js` file:
```js
// It's not valid JS yet.
window.globalConfig = {
  GOOGLE_CLIENT_ID: ${googleClientId},
  BACKEND_BASE_URL: ${backendBaseUrl},
  STATIC_LANDING_URL: ${staticLandingUrl}
};
```

We also have a `mappings.json` file in this repo that maps skel templated "values" to SSM parameters:

```json
{
  "googleClientId": "/notifycal/${environment}/providers/google/oauth2/client_secret",   // Not stack-dependant
  "backendBaseUrl": "/notifycal/${environment}/backend/url",
  "staticLandingUrl": "/notifycal/${environment}/static-landing/url",
}
```

Note how the mappings file also exposes `environment` as something to template/interpolate.

Now we can run the `service-discovery.py` program/script to generate a final config file for a given environment. This scripts resolves the `.skel.js` mappings with `mappings.json`, `environment` with the environment name, and retrieves each key from SSM.

```
$ python service-registration/service-discovery.py \
  --environment prod \
  --skel_file frontend.skel.js \
  --mappings_file mappings.json > config.js
```

If a key is either not found in the mapping.json file, or in SSM, we'll automatically set it to `null`. That should trigger a failure when the frontend tries to process the config.

### Sample generated config.js file
```js
window.globalConfig = {
  GOOGLE_CLIENT_ID: 'XXXXX-XXXXXXX.apps.googleusercontent.com',
  BACKEND_BASE_URL: "https://apidev.notifycal.com",
  // Example, in case a key is not in SSM or cannot resolve the mapping.
  STATIC_LANDING_URL: null    
};
```

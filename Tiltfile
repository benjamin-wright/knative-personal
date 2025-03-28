allow_k8s_contexts(['k3d-knative-test'])

k8s_kind('Service', api_version='serving.knative.dev/v1',
         image_json_path='{.spec.template.spec.containers[*].image}')

custom_build(
    'wasm',
    'IMAGE=$EXPECTED_REF make image',
    ['./apps/svc1'],
    ignore=['target'],
)

k8s_yaml(helm('./deploy', set=['name=wasm', 'image=wasm', 'runtimeClassName=wasmedge']))

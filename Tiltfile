allow_k8s_contexts(['k3d-knative-test'])

k8s_kind('Service', api_version='serving.knative.dev/v1',
         image_json_path='{.spec.template.spec.containers[*].image}')

custom_build(
    'wasm',
    'IMAGE=$EXPECTED_REF make image',
    ['./apps/svc1'],
    ignore=['target'],
)

k8s_yaml(helm('./deploy', set=['name=wasm', 'image=wasm', 'runtimeClassName=wasmedge', 'nodeName=k3d-knative-test-server-0']))

custom_build(
    'rust',
    'IMAGE=$EXPECTED_REF make rust',
    ['./apps/svc1'],
    ignore=['target'],
)

k8s_yaml(helm('./deploy', set=['name=rust', 'image=rust', 'nodeName=k3d-knative-test-server-0']))

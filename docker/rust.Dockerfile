FROM scratch

COPY wasm.wasm /wasm

ENTRYPOINT [ "/wasm" ]

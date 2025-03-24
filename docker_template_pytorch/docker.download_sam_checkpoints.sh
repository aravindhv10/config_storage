#!/bin/sh
mkdir -pv -- "${HOME}/.cache/SHA512SUM"

. "${HOME}/important_functions.sh"

adown \
    'https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_tiny.pt' \
    'sam2.1_hiera_tiny.pt' \
    'df6fe66086c6e127f9932be2d0bc0a0c57f087c0e142427bea5ef7b71626e131e2755984df0bcd76b119e9dc0cc9dc33a8842e31ce445b3658ce77abe8789e2b'
    "${HOME}/sam2/checkpoints/sam2.1_hiera_tiny.pt" \
;

adown \
    'https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_small.pt' \
    'sam2.1_hiera_small.pt' \
    'f6a1ab87b096fd6753ed2b7cfbb13695ad3ceb7a3dc3ea433f23571c0db2369ee372d27da3be9bce39c53ffc84a7e9a30c6879e5b1b418898d831442039264c6' \
    "${HOME}/sam2/checkpoints/sam2.1_hiera_small.pt" \
;

adown \
    'https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_base_plus.pt' \
    'sam2.1_hiera_base_plus.pt' \
    '0c4f89b91f1f951b95246f9544f32d93d370aaf10c30344d47df0cfa3316a819cffd0042ab462244198ae8261d56fa4cc93bf916b4c9f4450d651ac3faa9a7cd' \
    "${HOME}/sam2/checkpoints/sam2.1_hiera_base_plus.pt" \
;

adown \
    'https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_large.pt' \
    'sam2.1_hiera_large.pt' \
    '2672dacbbd40f9d8e0fffb80696316054e1a32f32a8241c89492e532f0607f1dc2bf0913f6688cfeb7521b02bb16c90b3ed4e90f53568c1f60f0c610f21ef21f' \
    "${HOME}/sam2/checkpoints/sam2.1_hiera_large.pt" \
;

#!/bin/bash

# DKMS에 추가되거나 설치된 모든 NI (National Instruments) 드라이버 모듈을
# 찾아 자동으로 삭제하는 스크립트입니다.
#
# 이 스크립트는 반드시 root 권한으로 실행해야 합니다. (e.g., sudo ./remove-ni-dkms.sh)

# 스크립트 실행 중 오류가 발생하면 즉시 중단
set -e

# root 사용자인지 확인
if [ "$EUID" -ne 0 ]; then
  echo "오류: 이 스크립트는 반드시 root 권한으로 실행해야 합니다. (sudo ./remove-ni-dkms.sh)"
  exit 1
fi

echo "--- DKMS에 등록된 모든 NI 드라이버 모듈 삭제를 시작합니다 ---"

# dkms status 결과에서 'ni'로 시작하는 모든 모듈을 찾아 삭제
# awk를 사용해 '모듈명/버전: 상태' 형식에서 ': ' 앞부분만 추출합니다.
dkms status | grep '^ni' | awk -F': ' '{print $1}' | while read -r module
do
    if [ -n "$module" ]; then
        echo "==> 삭제 중: ${module}"
        dkms remove "${module}" --all
    fi
done

echo ""
echo "--- 작업 완료 후 최종 DKMS 상태를 확인합니다 ---"
dkms status
echo ""
echo "--- 모든 NI DKMS 모듈이 성공적으로 삭제되었습니다! ---"

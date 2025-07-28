#!/bin/bash

# NI (National Instruments) Linux DKMS 드라이버 설치 문제를 해결하는 스크립트
# RHEL 9, Rocky Linux 9 등 최신 배포판에서 발생하는 dkms.conf 호환성 문제를 해결합니다.
#
# 이 스크립트는 반드시 root 권한으로 실행해야 합니다. (e.g., sudo ./fix-ni-dkms.sh)

# 스크립트 실행 중 오류가 발생하면 즉시 중단
set -e

# root 사용자인지 확인
if [ "$EUID" -ne 0 ]; then
  echo "오류: 이 스크립트는 반드시 root 권한으로 실행해야 합니다. (sudo ./fix-ni-dkms.sh)"
  exit 1
fi

echo "--- NI Linux DKMS 드라이버 문제 해결 스크립트를 시작합니다 ---"

# 1단계: 모든 dkms.conf 파일에서 호환되지 않는 라인 삭제
echo ""
echo "==> 1단계: 호환되지 않는 dkms.conf 파일을 찾아 수정합니다..."
# /usr/src 경로에서 dkms.conf 파일을 찾아 'NO_WEAK_MODULES' 라인을 삭제하고, 원본은 .bak 파일로 백업합니다.
find /usr/src -name "dkms.conf" -type f -exec sed -i.bak '/NO_WEAK_MODULES/d' {} +
echo "==> dkms.conf 파일 수정이 완료되었습니다."

# 2단계: 모든 NI 드라이버 모듈을 DKMS 트리에 수동으로 추가
echo ""
echo "==> 2단계: 모든 NI 모듈을 DKMS에 추가합니다..."
# /usr/src 디렉토리에서 NI 드라이버 소스 폴더를 찾아 dkms add 명령을 실행합니다.
for d in $(ls -d /usr/src/ni*-*f*/ 2>/dev/null); do
    echo "  -> 추가 중: ${d%/}"
    dkms add "${d%/}"
done
echo "==> 모든 모듈이 DKMS에 추가되었습니다."

# 3단계: 추가된 모든 모듈을 현재 커널에 맞게 빌드 및 설치
echo ""
echo "==> 3단계: DKMS 모듈을 빌드하고 설치합니다 (autoinstall)..."
dkms autoinstall

# 4단계: 최종 결과 확인
echo ""
echo "==> 4단계: 최종 DKMS 상태를 확인합니다..."
dkms status

echo ""
echo "--- 모든 작업이 성공적으로 완료되었습니다! ---"

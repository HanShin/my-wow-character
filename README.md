# Midnight BiS Guide

Retail Midnight 현재 시즌용 장비 점검 애드온입니다.

기능:

- 현재 장착 장비와 시즌별 기본 BiS 비교
- `레이드 가능` / `레이드 불가` 두 가지 목표 세팅 분리
- 모든 장비 부위의 목표 아이템과 획득처 표시
- 캐릭터별 사용자 BIS 편집
- 시즌 던전/레이드 목록에서 itemID 없이 목표 아이템 선택
- 아이템 링크 표시와 `신화쐐기돌 / 레이드 / 제작 / 주간 금고 / 촉매` 획득처 분리 표시
- 슬롯 단위 복원과 현재 모드 전체 복원

사용법:

- `/bis`: 창 열기/닫기
- `/bis raid`: 레이드 가능/불가 토글
- `/bis spec`: 현재 클래스 내 특성 순환
- `/bis spec auto`: 현재 활성 특성 자동 추적으로 복귀

설치:

- `MidnightBisGuide/` 폴더를 그대로 `Interface/AddOns/` 아래에 배치합니다.

## 데이터 생성

기본 BiS 데이터는 현재 시즌 Wowhead class BiS guide 40개 전부를 기준으로 생성합니다. 시즌 레이드 보스별 loot table은 Wowhead raid guide를 사용하고, 시즌 던전 loot table과 일부 레이드 불가 보완 후보는 Icy Veins를 함께 사용합니다.

```bash
python3 scripts/generate_default_data.py
```

생성 결과는 `MidnightBisGuide/Data/SeasonData.lua`와 `MidnightBisGuide/Data/SeasonContent.lua`에 기록됩니다.

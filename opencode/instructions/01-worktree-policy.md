---
# Worktree Policy (Auto)

목표: 병렬 작업/실수 복구/리뷰 가능성을 높이기 위해, 코딩 작업은 worktree를 기본으로 사용한다.

## 언제 worktree를 “반드시” 쓰나?
- 1개 파일 이상 수정이 예상되는 코딩 작업
- 테스트/빌드 실행이 필요한 작업
- 리팩터링/구조 변경/의존성 변경
- 동일 레포에서 병렬로 다른 일을 하고 있거나(세션/브랜치가 많음), 충돌 위험이 있을 때
- 요구사항이 불명확하여 “되돌림” 가능성이 높을 때

## 예외(Worktree 생략 가능)
- 레포가 git이 아닐 때
- 단일 파일의 아주 작은 수정(예: 10줄 미만, 위험도 낮고 테스트 불필요)이며 사용자가 worktree를 원치 않는다고 명시했을 때

## 표준 worktree 위치(레포 밖)
- repoRoot = `git rev-parse --show-toplevel`
- repoName = repoRoot basename
- worktreesBase = `<repoRoot의 부모>/.worktrees/<repoName>/`
- worktreePath = `<worktreesBase>/<taskSlug>`
- 브랜치명 = `wt/<taskSlug>`

## 생성/사용 알고리즘(요약)
1) repoRoot 찾기
2) taskSlug 생성(짧고 안전한 문자열, 예: 20260303-fix-login-redirect)
3) `git worktree add -b wt/<slug> <worktreePath>`
4) 이후 모든 구현/테스트는 worktreePath에서 수행
5) 완료 후:
   - PR/머지 또는 main 워크트리에 cherry-pick 등 선택
   - `git worktree remove <worktreePath>`
   - 필요 시 `git branch -D wt/<slug>` 정리
---

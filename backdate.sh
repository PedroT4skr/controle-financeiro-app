export FILTER_BRANCH_SQUELCH_WARNING=1
git update-index --refresh
rm -f .date_counter
git filter-branch -f --env-filter '
  if [ ! -f .date_counter ]; then echo 0 > .date_counter; fi
  COUNTER=$(cat .date_counter)
  SEC=$(expr $COUNTER % 60)
  MIN=$(expr 30 + $COUNTER / 60)
  export GIT_AUTHOR_DATE="2026-06-05 22:$MIN:$SEC -0300"
  export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"
  echo $(expr $COUNTER + 1) > .date_counter
' 59304f2..HEAD
git push origin main --force
rm -f .date_counter

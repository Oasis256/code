WORD="$1" ; shift
# find . -name "*.uc" |
find */Classes Epic/*/Classes Decompiled/*/Classes -name "*.uc" |
grep -v "/CVS/Base/" |
# xargs grep -i "\<$1\>" |
# xargs grep -i "$@" |
IKNOWIDONTHAVEATTY=1 memo -t "1 hour" xargs grep -i "\<$WORD\>" "$@" |
# highlight "\<$WORD\>" |
highlight "\<`caseinsensitiveregex "$WORD"`\>" |
more -f

report_id="dcd172cf-1865-4ab5-b5f8-2266c6420966"
report_name="arba_copy"
return_link=0

while :; do
case $1 in
  -p|--project)
		shift
		project_id=$1
		;;
	-d|--dataset)
		shift
		dataset_id=$1
		;;
  -L|--link)
    return_link=1
    ;;
	-n|--report-name)
		shift
		report_name=`echo "$1" | tr  " " "_"`
		;;
	-h|--help)
		echo -e $usage;
		exit
		;;
	*)
		break
	esac
	shift
done

	link=`cat $(dirname $0)/linking_api.http | sed "s/REPORT_ID/$report_id/; s/REPORT_NAME/$report_name/; s/YOUR_PROJECT_ID/$project_id/g; s/YOUR_DATASET_ID/$dataset_id/g" | sed '/^$/d;' | tr -d '\n'`
if [ $return_link -eq 1 ]; then
  echo "$link"
else
  open "$link"
fi

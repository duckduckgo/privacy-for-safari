
### Builder arguments - update these if the location of the tracker lists changes

# Assumes branch 'apple-list-1-nodeup' from  git@dub.duckduckgo.com:jason/tracker-lists.git 
trackersProject=../tracker-lists

# The trackers folder (contains json file for each tracker)
trackers=$trackersProject/export-data/apple-contract-1

# The entities folder (contains json file for each entity)
entities=$trackersProject/entities

# Where the consolidated tracker data (trackers + entities) ends up
trackerData=TrackerBlocking/trackerData.json

# Where to put the sample blocker rules output
blockerRules=/var/tmp/blockerRules.json

# Build the command line app
fastlane gym --scheme TrackersBuilder -o /var/tmp

echo
echo "***"
echo "*** Building $trackerData from $trackers and $entities"
echo "*** Sample blocker rules can be found at $blockerRules"
echo "***"
echo

/var/tmp/TrackersBuilder $trackers $entities $trackerData $blockerRules 

echo
echo "*** Done"
echo 


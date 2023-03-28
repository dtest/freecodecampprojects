#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

echo "$($PSQL "TRUNCATE teams, games")"

# Declare global variables
TEAMS=[]
FOUND_TEAM=""

# Check if a team has already been inserted
INTEAMS() {
  FOUND_TEAM=""
  for i in "${!TEAMS[@]}"; do
    if [[ "${TEAMS[$i]}" = "${1}" ]]; then
       FOUND_TEAM="${i}"
       break
    fi
  done
}


# for each row in games.csv
while IFS=',' read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # ignore header row
  if [[ $YEAR == 'year' ]]
  then
    continue
  fi

  # check if team id exists for the winning team from an array
  INTEAMS "$WINNER"
  WINNING_TEAM_ID=$FOUND_TEAM

  # if not, insert winning team and get the team_id; store in array
  if [[ -z $WINNING_TEAM_ID ]]
  then
    echo "Team not found. Insert winning team, $WINNER"

    WINNING_TEAM_ID=$($PSQL "INSERT INTO teams (name) VALUES ('$WINNER') RETURNING team_id" | grep -E '^[0-9]')
    TEAMS[$WINNING_TEAM_ID]=$WINNER
  fi

  # check if team id exists for the opponent team from an array
  INTEAMS "$OPPONENT"
  OPPONENT_TEAM_ID=$FOUND_TEAM

  # if not, insert opponent team and get the team_id; store in array
  if [[ ! "${TEAMS[@]}" =~ "$OPPONENT" ]]
  then
    echo "Team not found. Insert opponent team, $OPPONENT"

    OPPONENT_TEAM_ID=$($PSQL "INSERT INTO teams (name) VALUES ('$OPPONENT') RETURNING team_id" | grep -E '^[0-9]')
    TEAMS[$OPPONENT_TEAM_ID]=$OPPONENT
  fi

  if [[ -z $WINNING_TEAM_ID || -z $OPPONENT_TEAM_ID ]]
  then
    echo "Either the Winning team ( ${WINNING_TEAM_ID} ) or Opponent team ( ${OPPONENT_TEAM_ID} ) is missing. "
    echo "Cannot enter row"
    continue
  fi

  # insert game information into games table
  RES=$($PSQL "INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($YEAR, '$ROUND', $WINNING_TEAM_ID, $OPPONENT_TEAM_ID, $WINNER_GOALS, $OPPONENT_GOALS)")
  echo "Entering game ($WINNER v $OPPONENT). Results: $RES"

done < games.csv
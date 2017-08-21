#!/bin/bash
# A version of mastermind

# First generate a random 4 digit code
GENERATED=$(printf "%04d\n" $(( RANDOM %= 9999 )))
GUESS='0'
ATTEMPTS=12

# Create a temp file that will be used to display game status to the user.
GAMESTATE=$(mktemp)
echo '+-+-+-+-+-+-+-+-+-+-+' >> $GAMESTATE
echo '|M|a|s|t|e|r|m|i|n|d|' >> $GAMESTATE
echo '+-+-+-+-+-+-+-+-+-+-+' >> $GAMESTATE

# Display rules
echo '+-+-+-+-+-+-+-+-+-+-+'
echo '|M|a|s|t|e|r|m|i|n|d|'
echo '+-+-+-+-+-+-+-+-+-+-+'
echo '+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+'
echo '+    HOW TO PLAY    +              TOKEN TYPES              +'
echo '+-------------------+---------------------------------------+'
echo '+ Try to guess the  + (#) = One digit is a match and IS     +'
echo '+ 4 digit number in +       in the correct position.        +'
echo '+ the fewest tries. +                                       +'
echo '+                   + (?) = One digit is a match and IS NOT +'
echo '+ After each guess  +       in the correct position.        +'
echo '+ you are awarded   +                                       +'
echo '+ feedback tokens.  + (-) = One digit is not a match.       +'
echo '+                   +                                       +'
echo '+ Use the feedback  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+'
echo '+ to help work out  +'
echo '+ the number.       +'
echo '+                   +'
echo '+-+-+-+-+-+-+-+-+-+-+'
echo

# Check if the guess is correct. If not, loop this until it is.
while [ $GENERATED != $GUESS ] && [ $ATTEMPTS -gt 0 ]
do
    
    # Tell the user how many attempts they have left
    if [ $ATTEMPTS -gt 1 ]
    then
        echo "$ATTEMPTS"' attempts remaining.'
    elif [ $ATTEMPTS -eq 1 ]
    then
        echo 'THIS IS YOUR LAST ATTEMPT!'
    fi

    # Take in player INPUT
    read -p 'Enter a number: ' INPUT
    
    # Validate INPUT and assign to GUESS
    while [[ ! $INPUT =~ ^[0-9]+$ ]] || [ ${#INPUT} != 4 ]
    do
        echo 'You need to enter a 4 digit number!'
        read -p 'Enter a number: ' INPUT
    done
    
    # Write attempt number to GAMESTATE
    echo '+-+-+-+-+-+-+-+-+-+-+' >> $GAMESTATE
    echo '+ ATTEMPT : '$( printf "%03d" $(( 13-ATTEMPTS )) )'/'$( printf "%03d" 12 ) '+' >> $GAMESTATE
 
    # Assign the INPUT to GUESS and decrease ATTEMPTS
    GUESS=$INPUT
    (( ATTEMPTS-- ))
    clear
    # Initialise the CHECK arrays
    GENERATED_CHECK=( UNMATCHED UNMATCHED UNMATCHED UNMATCHED )
    GUESS_CHECK=( UNMATCHED UNMATCHED UNMATCHED UNMATCHED )

    # Check how many HIT
    for ITERATION in {1..4}
    do
        # If there is a HIT then award a HIT token
        if [ $(echo $GENERATED | cut -c $ITERATION) = $(echo $GUESS | cut -c $ITERATION) ]
        then
            GENERATED_CHECK[$(( ITERATION - 1))]=HIT
            GUESS_CHECK[$(( ITERATION - 1))]=HIT
        fi
    done

    # Check how many MATCH
    # Cycle through each DIGIT of GUESS
    for DIGIT_GUESS in {1..4}
    do

        # Cycle through each DIGIT of GENERATED
        for DIGIT_GENERATED in {1..4}
        do
            
            # Use CHECKS to see if a token has been alredy awarded 
            if [ ${GENERATED_CHECK[$(( DIGIT_GENERATED - 1))]} = UNMATCHED ] && [ ${GUESS_CHECK[$(( DIGIT_GUESS - 1))]} = UNMATCHED ]
            then

                # If it hasn't, check if the DIGITS of GENERATED and GUESS match
                if [ $(echo $GENERATED | cut -c $DIGIT_GENERATED) = $(echo $GUESS | cut -c $DIGIT_GUESS) ]
                then

                    # If there is a MATCH, award a MATCH token
                    GENERATED_CHECK[$(( DIGIT_GENERATED - 1))]=MATCH
                    GUESS_CHECK[$(( DIGIT_GUESS - 1))]=MATCH
       
                fi
               
            fi
            
        done

    done


    # Sort the TOKENS so they don't give away their position
    TOKENS_AWARDED=( $(
        for TOKEN in ${GUESS_CHECK[@]}
        do
            if [ $TOKEN = HIT ]
            then
                echo '(#)'
            elif [ $TOKEN = MATCH ]
            then
                echo '(?)'
            else
                echo '(-)'
            fi
        done | sort -r) )

    # Write tokens awarded to GAMESTATE
    echo '+-------------------+' >> $GAMESTATE
    echo '+        '$GUESS'       +' >> $GAMESTATE
    echo '+-------------------+' >> $GAMESTATE
    echo '+  '"${TOKENS_AWARDED[@]}"'  +' >> $GAMESTATE
    echo '+-+-+-+-+-+-+-+-+-+-+' >> $GAMESTATE

    # Show the player the state of the game
    clear
    cat $GAMESTATE
    echo

done

# Check if number was guessed correctly (in case the IF statement crashed out for some reason)
if [ $GENERATED = $GUESS ]
then
    echo "CRACKED IT!"
    echo "The code was: $GENERATED"
elif [ $ATTEMPTS -le 0 ]
then
    echo "TOO BAD!"
    echo "The code was: $GENERATED"
fi

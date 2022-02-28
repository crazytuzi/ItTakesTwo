import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleMother;

class USnowGlobeTurtleMotherAnimInstance : UHazeAnimInstanceBase
{
    UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData TurtleEnteredNest1;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData TurtleEnteredNest2;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData TurtleEnteredNest3;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData TurtleEnteredNest4;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData PlayingMelody;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData SnowballHitReaction;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector LookAtLocation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bPlayHappyAnimation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bEnableLookAt;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bSnowBallHit;

	ASnowTurtleMother TurtleMotherActor;

	bool bClosestCharIsCody;
	FTimerHandle LookAtTimer;
	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;

	// Nest variables
	ASnowTurtleNest NestOne, NestTwo, NestThree, NestFour;
	bool bNestOneOccupied, bNestTwoOccupied, bNestThreeOccupied, bNestFourOccupied;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int NumberOfNestsOccupied;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bInteractNestOne = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bInteractNestTwo = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bInteractNestThree = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bInteractNestFour = false;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        TurtleMotherActor = Cast<ASnowTurtleMother>(OwningActor);
		if (TurtleMotherActor == nullptr)
			return;

			
		LookAtTimer = System::SetTimer(this, n"GetClosesCharacter", 5.f, true);
		GetNestReferences();
	}

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (TurtleMotherActor == nullptr)
            return;

		// Calculate the look at location
		FVector NewLookAtLocation;
		if (bClosestCharIsCody && Cody != nullptr)
			NewLookAtLocation = Cody.ActorLocation;
		else if (May != nullptr)
			NewLookAtLocation = May.ActorLocation;
		else
			bEnableLookAt = false;

		if (bEnableLookAt)
			LookAtLocation = FMath::VInterpTo(LookAtLocation, NewLookAtLocation, DeltaTime, 3.f);


		// Check if a turtle has entered a nest and if so play an interact animation
		bPlayHappyAnimation = GetAnimBoolParam(n"IsHappy", true);

		bSnowBallHit = GetAnimBoolParam(n"bHitBySnowball", true);

		CheckIfTurtleEnteredNest(NestOne, bNestOneOccupied, bInteractNestOne);
		CheckIfTurtleEnteredNest(NestTwo, bNestTwoOccupied, bInteractNestTwo);
		CheckIfTurtleEnteredNest(NestThree, bNestThreeOccupied, bInteractNestThree);
		CheckIfTurtleEnteredNest(NestFour, bNestFourOccupied, bInteractNestFour);

		bPlayHappyAnimation = (bInteractNestOne || bInteractNestTwo || bInteractNestThree || bInteractNestFour);
    }


	UFUNCTION()
	void GetNestReferences()
	{
		int i = 0;
		for (ASnowTurtleNest Nest : TurtleMotherActor.NestsArray)
		{
			if (i == 0)
			{
				NestOne = Nest;
			}
			else if (i == 1)
			{
				NestTwo = Nest;
			}
			else if (i == 2)
			{
				NestThree = Nest;
			}
			else if (i == 3)
			{
				NestFour = Nest;
			}
			i++;
		}
	}

	UFUNCTION()
	void ResetInteractBool(int NestNumber)
	{
		if (NestNumber == 1)
		{
			bInteractNestOne = false;
		}
		else if (NestNumber == 2)
		{
			bInteractNestTwo = false;
		}
		else if (NestNumber == 3)
		{
			bInteractNestThree = false;
		}
		else if (NestNumber == 4)
		{
			bInteractNestFour = false;
		}
	}

	UFUNCTION()
	void CheckIfTurtleEnteredNest(ASnowTurtleNest Nest, bool& bNestOccupied, bool& bInteractWithNest)
	{
		if (Nest == nullptr)
		{
			return;
		}
		if (bNestOccupied)
			return;
		if(Nest.bIsOccupied)
		{
			bNestOccupied = true;
			bInteractWithNest = true;
			NumberOfNestsOccupied++;
			Print("NumberOfNestsOccupied: " + NumberOfNestsOccupied, 500.f);
		}
	}


	UFUNCTION()
	void GetClosesCharacter()
	{
		if (TurtleMotherActor == nullptr)
            return;

		Game::GetMayCody(May, Cody);
		if (May == nullptr || Cody == nullptr)
			return;
		
		const FVector ActorLocation = OwningActor.ActorLocation;
		const float DistanceToMay = (ActorLocation - May.ActorLocation).Size();
		const float DistanceToCody = (ActorLocation - Cody.ActorLocation).Size();
		if (DistanceToCody < DistanceToMay)
		{
			bClosestCharIsCody = true;
			bEnableLookAt = (DistanceToCody < 13000.f);
		}
		else
		{
			bClosestCharIsCody = false;
			bEnableLookAt = (DistanceToMay < 13000.f);
		}
	}
}
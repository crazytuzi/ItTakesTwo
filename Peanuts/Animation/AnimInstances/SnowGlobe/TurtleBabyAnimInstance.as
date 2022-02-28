;import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;

class UTurtleBabyAnimInstance : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData EnterHide;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData HiddenMh;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData ExitHide;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData ExitHideFast;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData PlayerInTheWay;

	UPROPERTY(BlueprintReadOnly)
	FHazePlayBlendSpaceData InNestArea;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData EnterNest;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData NestMh;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData Callout;
	

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHidden;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHaveEnteredNestArea;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsInNest;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bInteruptExitHidingAnim;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayerIsInTheWay;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCallout;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAllowCallout;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector LocalVelocity;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D InNestAreaBlendspaceValues;

	ASnowTurtleBaby TurtleActor;
	FRotator ActorRotation;
	AHazePlayerCharacter Cody;
	AHazePlayerCharacter May;

	// If player is within this rage, play callout animation
	const int DistanceToCallout = 3500;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		if (OwningActor == nullptr)
			return;

		TurtleActor = Cast<ASnowTurtleBaby>(OwningActor);

		Game::GetMayCody(May, Cody);
		bAllowCallout = true;
		
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (TurtleActor == nullptr)
			return;

		bIsInNest = TurtleActor.bIsInNest;
		LocalVelocity = OwningActor.ActorRotation.UnrotateVector(OwningActor.ActorVelocity);

		if (bIsInNest)
		{
			return;
		}

		
		

		bHaveEnteredNestArea = TurtleActor.bHaveEnteredNestArea;

		if (bHaveEnteredNestArea) 
		{
			// Calculate the rotation current rotation rate
			const FRotator NewSkelMeshRotation = TurtleActor.SkeletalMeshComponent.GetWorldRotation();
			InNestAreaBlendspaceValues.X = FMath::Clamp(((ActorRotation - NewSkelMeshRotation).Yaw / DeltaTime) * -1.f, -100.f, 100.f);
			InNestAreaBlendspaceValues.Y = LocalVelocity.Size() * 0.75f;
			ActorRotation = NewSkelMeshRotation;
			bPlayerIsInTheWay = TurtleActor.bPlayerIsInTheWay;
			ExitHiding();
			return;
		}
		
		if (TurtleActor.bMayIsAffecting || TurtleActor.bCodyIsAffecting || LocalVelocity.Size() > 100.f || GetAnimBoolParam(n"bHitBySnowball", true))
		{
			bHidden = true;
			System::SetTimer(this, n"ExitHiding", 1.5f, false);
			bInteruptExitHidingAnim = GetAnimBoolParam(n"PlayExit", true);
			return;
		}



		// Callout functionality, Call out to player when player is within a certain range.

		if (!bAllowCallout && !bHidden)
		{
			bCallout = false;
			return;
		}

		// Make sure none of the players are nullptrs
		if (!ValidCheckPlayers())
			return;
		
		// Check if player is within range, if so do a callout
		if ((OwningActor.ActorLocation - May.ActorLocation).Size() < DistanceToCallout || (OwningActor.ActorLocation - Cody.ActorLocation).Size() < DistanceToCallout)
		{
			bCallout = true;
			bAllowCallout = false;
			const float TimeUntilNextCallout = FMath::RandRange(5.f, 10.f);
			System::SetTimer(this, n"AllowCalloutAgain", TimeUntilNextCallout, false);
		}
		
	}

	UFUNCTION()
	bool ValidCheckPlayers()
	{
		if (May == nullptr || Cody == nullptr)
		{
			Game::GetMayCody(May, Cody);
			return (May != nullptr && Cody != nullptr);
		}
		return true;
	}

	UFUNCTION()
	void AllowCalloutAgain()
	{
		bAllowCallout = true;
	}

	UFUNCTION()
	void ExitHiding()
	{
		bHidden = false;
	}

}
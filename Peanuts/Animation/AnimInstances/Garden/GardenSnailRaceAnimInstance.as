import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceSnailActor;
import Peanuts.Animation.AnimInstances.Garden.GardenSnailRacePlayerAnimInstance;

class UGardenSnailRaceAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Dash;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Stunned;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float StartPosition;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float TurnRate;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float SquishValue;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bBoost;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsStunned;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bGameIsStartingOnRemote;

	FRotator ActorRotation;
	ASnailRaceSnailActor Snail;
	UGardenSnailRacePlayerAnimInstance PlayerAnimInstance;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Snail = Cast<ASnailRaceSnailActor>(OwningActor);

		// Give the mh a random start position to offset the two snails
		StartPosition = FMath::RandRange(0.f, 1.f);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (Snail == nullptr)
            return;
		
		if (Snail.RidingPlayer == nullptr)
		{
			SquishValue = 0.f;
			TurnRate = 0.f;
			return;
		}
		
		const float DeltaRotation = (ActorRotation - OwningActor.ActorRotation).Normalized.Yaw;
		if (DeltaTime != 0.f)
			TurnRate = -FMath::Clamp((DeltaRotation / DeltaTime) / 200.f, -1.f, 1.f);
		ActorRotation = OwningActor.ActorRotation;

		if (Snail.HasControl())
			bBoost = Snail.SnailBoost > SMALL_NUMBER;
		else if (!bGameIsStartingOnRemote)
		{
			bBoost = false;
			if (SquishValue > 0.01f && OwningActor.GetActorVelocity().Size() > 1500.f)
			{
				bBoost = true;
			}
		}


		SquishValue = 1.f - (Snail.SquishValue - 0.2f) * 1.25f;

		// On the remote side it has 1.25f value before the game has started
		bGameIsStartingOnRemote = (SquishValue == 1.25f);
		Snail.RidingPlayer.SetAnimFloatParam(n"SquishValue", SquishValue);
		if (bGameIsStartingOnRemote)
			SquishValue = 0.f;

		
		bIsStunned = Snail.bIsStunned;


		// Send values to the player
		Snail.RidingPlayer.SetAnimBoolParam(n"bBoost", bBoost);
		Snail.RidingPlayer.SetAnimBoolParam(n"bIsStunned", bIsStunned);
		Snail.RidingPlayer.SetAnimFloatParam(n"StartPosition", StartPosition);
    }

}
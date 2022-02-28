import Cake.LevelSpecific.Hopscotch.Bumper;
import Vino.Movement.MovementSystemTags;

class UBumperCapability : UHazeCapability
{

    TArray<ABumper> BumperArray;
	ABumper CurrentBumper;
	ABumper BumperBoy;
	bool bShouldMovePlayer;
	int IndexToMoveTo;
	
	bool bFallingWasUnblocked;
	default CapabilityTags.Add(n"Bumper");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		GetAllActorsOfClass(BumperArray);

		for (ABumper Bumper : BumperArray)
		{
			Bumper.BumperEvent.AddUFunction(this, n"StartBumping");
			
		}
	}

	UFUNCTION()
	void StartBumping(ABumper Bumper, AHazePlayerCharacter PlayerTriggered)
	{
		if (Player == PlayerTriggered)
		{
			IndexToMoveTo = 1;
			bShouldMovePlayer = true;
			CurrentBumper = Bumper;
			Player.SetCapabilityActionState(n"Bumping", EHazeActionState::Active);
			
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"Bumping"))
            return EHazeNetworkActivation::ActivateFromControl;
         
         else
            return EHazeNetworkActivation::DontActivate;    
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!IsActioning(n"Bumping"))
		    return EHazeNetworkDeactivation::DeactivateFromControl;

        else
		    return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        bFallingWasUnblocked = false;

        Player.BlockCapabilities(CapabilityTags::MovementInput, this);
        Player.BlockCapabilities(MovementSystemTags::Falling, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		BumperBoy = Cast<ABumper>(GetAttributeObject(n"Bumper"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	    Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
        
        if (!bFallingWasUnblocked)
            Player.UnblockCapabilities(MovementSystemTags::Falling, this);

        Player.SetCapabilityActionState(n"LastBumping", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bShouldMovePlayer)
			MovePlayerToBumper();

        if (IsActioning(n"LastBumping") && !bFallingWasUnblocked)
        {
            bFallingWasUnblocked = true;
            Player.UnblockCapabilities(MovementSystemTags::Falling, this);
        }
	}

	void MovePlayerToBumper()
	{
		FVector Direction = FVector (CurrentBumper.StaticMeshArray[IndexToMoveTo].GetWorldLocation() - Player.GetActorLocation());
		float LengthToBumper = Direction.Size();
		Direction.Normalize();

		Player.SetActorLocation(FVector(Player.GetActorLocation() + FVector(Direction * 5000.f * Player.ActorDeltaSeconds)));

		if (FMath::IsNearlyZero(LengthToBumper, 100.f))
		{
			IndexToMoveTo++;

			if (IndexToMoveTo >= CurrentBumper.StaticMeshArray.Num())
			{
				Player.SetCapabilityActionState(n"Bumping", EHazeActionState::Inactive);
			}
		}
	}
}

UFUNCTION()
void StartBump(ABumper Bumper, AHazePlayerCharacter Player)
{
	Player.SetCapabilityActionState(n"Bumping", EHazeActionState::Active);
	Player.SetCapabilityAttributeObject(n"Bumper", Bumper);
}
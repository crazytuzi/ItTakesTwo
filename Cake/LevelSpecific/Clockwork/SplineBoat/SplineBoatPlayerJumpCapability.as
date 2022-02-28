import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPlayerComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatJumpComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;

class USplineBoatPlayerJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SplineBoatPlayerJumpCapability");
	default CapabilityTags.Add(n"SplineBoat");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	// USplineBoatJumpComponent JumpComp;

	UHazeMovementComponent MoveComp;

	bool bHaveAttached;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		// JumpComp = USplineBoatJumpComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.DownHit.bBlockingHit)
		{
			ASplineBoatActor BoatActor = Cast<ASplineBoatActor>(MoveComp.DownHit.Actor);

			if (BoatActor != nullptr)
			{
				if (!bHaveAttached)
				{
					bHaveAttached = true;
					Player.AttachToActor(BoatActor, NAME_None, EAttachmentRule::KeepWorld); 
				}
			}
			else
			{
				if (bHaveAttached)
				{
					bHaveAttached = false;
					Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld); 
				}
			}
		}
	}

}
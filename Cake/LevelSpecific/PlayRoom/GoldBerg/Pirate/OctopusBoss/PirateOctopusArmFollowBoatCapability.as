import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArm;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArmFollowBoatComponent;

class UPirateOctopusArmFollowBoatCapability : UHazeCapability
{
    default CapabilityTags.Add(n"PirateOctopus");

    default TickGroup = ECapabilityTickGroups::LastMovement;

	APirateOctopusArm Arm;
	UPirateOctopusArmFollowBoatComponent FollowBoatComp;
	UWheelBoatStreamComponent StreamComponent;

	// FVector AddedSideOffset;	
	// FVector TargetLocation;

	// FRotator RotationTowardsTarget;
	// FVector NewLocation;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		Arm = Cast<APirateOctopusArm>(Owner);
		FollowBoatComp = UPirateOctopusArmFollowBoatComponent::Get(Arm);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!FollowBoatComp.bFollowBoat && !FollowBoatComp.bFaceBoat)
			return EHazeNetworkActivation::DontActivate;

    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!FollowBoatComp.bFollowBoat && !FollowBoatComp.bFaceBoat)
			 return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		StreamComponent = UWheelBoatStreamComponent::Get(Arm.PlayerTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}
	
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {			
		if(FollowBoatComp.bFollowBoat)
		{
			FHazeSplineSystemPosition FoundPosition;
			
			if (StreamComponent == nullptr || Arm.ActivatedStreamSpline == nullptr)
				return;

			const float MoveSpeed = StreamComponent.GetStreamMovementForce();
			FollowBoatComp.UpdateSplineMovement(MoveSpeed * DeltaTime, FoundPosition);
			FVector FinalWorldLocation = FoundPosition.WorldLocation;
			FinalWorldLocation.Z -= FollowBoatComp.ZOffset;
			Arm.SetActorLocation(FinalWorldLocation);
		}

		if(FollowBoatComp.bFaceBoat)
		{
			Arm.SetActorRotation(FollowBoatComp.FindRotationTowardsTarget(Arm.GetActorLocation(), Arm.PlayerTarget));
		}
	}
}
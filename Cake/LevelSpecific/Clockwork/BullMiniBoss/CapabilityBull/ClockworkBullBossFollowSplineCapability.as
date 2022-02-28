import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.CapabilityBull.ClockworkBullBossMoveCapability;

class UClockworkBullBossFollowSplineCapability : UClockworkBullBossMoveCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	const float SplineMultiplier = 4;
	const float FindTargetAngle = 15.f;

	FHazeSplineSystemPosition CurrentPosition;
	//AHazePlayerCharacter CurrentTarget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!BullOwner.CanInitializeMovement(MoveComp))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BullOwner.CanInitializeMovement(MoveComp))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(FMath::RandBool())
			ActivationParams.AddActionState(n"Forward");

		ActivationParams.AddValue(n"SplineDistance", FMath::RandRange(0.2f, 0.6f));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		// Break out of old capabilities
		SetMutuallyExclusive(MovementSystemTags::GroundMovement, true);
		SetMutuallyExclusive(MovementSystemTags::GroundMovement, false);

		bool bRandomForward = Params.GetActionState(n"Forward");

		CurrentPosition = BullOwner.MovementActor.Spline.GetPositionClosestToWorldLocation(BullOwner.ActorLocation, bRandomForward);
		CurrentPosition.Move(CurrentPosition.Spline.SplineLength * Params.GetValue(n"SplineDistance"));
		
		BullOwner.SplineFollowComponent.ActivateSplineMovement(CurrentPosition);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"BullSplineMove");

		if(HasControl())
		{
			float TraceDistance = 0;
			TraceDistance += BullOwner.CapsuleComponent.GetCapsuleHalfHeight() * 4;
			if(BullOwner.TargetIsInRange(CurrentPosition.WorldLocation, TraceDistance))
			{
				// Magic value so the bull don't catch up with the direction
				const float MoveAmount = FMath::Max(BullOwner.ActualVelocity.DotProduct(BullOwner.ActorForwardVector), 0.f);
				BullOwner.SplineFollowComponent.UpdateSplineMovement(MoveAmount * DeltaTime * SplineMultiplier, CurrentPosition);
			}

			FVector	TargetWorldLocation = CurrentPosition.WorldLocation;
			FVector TargetFacingDirection = (TargetWorldLocation - BullOwner.ActorLocation).GetSafeNormal();

			const float RotationSpeed = BullOwner.GetRotationSpeed(3.f);
		 	MoveComp.SetTargetFacingDirection(TargetFacingDirection, RotationSpeed);
		 	ApplyControlMovement(DeltaTime, FinalMovement, TargetWorldLocation);
		}
		else
		{
			// We need to update the position because the bull can change control side and then needs to have the correct spline location
			BullOwner.SplineFollowComponent.UpdateSplineMovement(CurrentPosition.WorldLocation, CurrentPosition);
			ApplyRemoteMovement(DeltaTime, FinalMovement, CurrentPosition.WorldLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "\n";
		return Str;
	} 
};

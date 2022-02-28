
import Cake.Weapons.Hammer.HammerWeaponStatics;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

import Cake.Weapons.Hammer.HammerableComponent;
import Cake.Weapons.Hammer.HammerWielderComponent;

import Peanuts.Aiming.AutoAimStatics;

class UHammerMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Weapon");
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"WeaponHammer");
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	float RotateWielderTowardsSmashDirection_Speed = 100.f;
	float AutoAimDistance_MIN = 0.f;
	float AutoAimDistance_MAX = 150.f;		// should be == Trace Length
	float TimeStampMovementTakeOver= 0.f;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	AHazePlayerCharacter Player = nullptr;
	UHammerWielderComponent	WielderComp = nullptr;
	UHammerWeaponSettings Settings = nullptr;

	FVector InitLocation = FVector::ZeroVector;
	FVector InitDirection = FVector::ZeroVector;

	// Transients 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UHammerWielderComponent::Get(Owner);
		Settings = UHammerWeaponSettings::GetSettings(WielderComp.Hammer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		// // This will allow normal movement to pass through a little while longer
		// const float TimeSinceAnimStarted = Time::GetGameTimeSince(WielderComp.TimeStampAnimationStarted); 
		// if(WielderComp.IsDoingHammeringAnimation() &&  TimeSinceAnimStarted > 0.26f)
		if(WielderComp.IsDoingHammeringAnimation())
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!WielderComp.IsDoingHammeringAnimation())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		const FVector SmashLocation = Player.GetActorLocation();
		FVector SmashDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (SmashDirection.IsNearlyZero())
		{
			// if we aren't moving the left stick we'll just pass through
			// the controlling sides forward in order to ensure that
			// the replica is facing the same direction.
			SmashDirection = Player.GetActorForwardVector();
			SmashDirection = SmashDirection.VectorPlaneProject(FVector::UpVector);
			SmashDirection.Normalize();
		}

		FAutoAimLine Aim = GetAutoAimForTargetLine(
			Player,
			SmashLocation,
			SmashDirection,
			AutoAimDistance_MIN,
			AutoAimDistance_MAX,
			bCheckVisibility = true
		);

		if (Aim.AutoAimedAtActor != nullptr)
		{
			const FVector TargetPoint = Aim.AutoAimedAtComponent.GetWorldLocation();
			SmashDirection = (TargetPoint - SmashLocation).GetSafeNormal();
		}

		if (!SmashDirection.IsNormalized())
			SmashDirection.Normalize();

// 		FVector DebugStart = SmashLocation;
// 		FVector DebugEnd = DebugStart + SmashDirection * 1000.f;
// 		System::DrawDebugLine(DebugStart, DebugEnd, FLinearColor::Yellow, 4.f, 4.f);

		NetInitHammerSmashMovement(SmashLocation, SmashDirection);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeStampMovementTakeOver= Time::GetGameTimeSeconds();
		SetMutuallyExclusive(CapabilityTags::Movement, true);

		Owner.TriggerMovementTransition(this);
  		MoveComp.SetControlledComponentTransform(InitLocation, MoveComp.GetOwnerRotation().Rotator());
 		MoveComp.SetTargetFacingDirection(InitDirection, 15.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) 
	{
		SetMutuallyExclusive(CapabilityTags::Movement, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
   		RotateWielderTowardsDesiredSmashDirection();

		if (!MoveComp.IsGrounded())
			DoAirMovement(DeltaTime);
		else
			DoGroundMovement(DeltaTime);
	}

	// Capability Functions
	//////////////////////////////////////////////////////////////////////////
	// Member functions

	UFUNCTION(NetFunction)
	void NetInitHammerSmashMovement(FVector DesiredLocation, FVector DesiredDirection)
	{
		InitLocation = DesiredLocation;
		InitDirection = DesiredDirection;
	}

	void DoAirMovement(const float DeltaTime) 
	{
		const bool bDebugHasControl = HasControl();

		FVector InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
		float MoveSpeed = MoveComp.MoveSpeed;

		FHazeFrameMovement ThisFrameMove = MoveComp.MakeFrameMovement(n"HammerMovement");
		ThisFrameMove.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, InputVector, MoveSpeed));

		ThisFrameMove.ApplyActorVerticalVelocity();

		ThisFrameMove.ApplyGravityAcceleration();
		ThisFrameMove.OverrideStepDownHeight(1.f);
		ThisFrameMove.OverrideStepUpHeight(0.f);		
		ThisFrameMove.ApplyTargetRotationDelta();

		MoveCharacter(ThisFrameMove, FeatureName::AirMovement);
	}

	void DoGroundMovement(const float DeltaTime) 
	{
		FHazeFrameMovement ThisFrameMove = MoveComp.MakeFrameMovement(n"HammerMovement");
		ThisFrameMove.ApplyTargetRotationDelta();
		MoveComp.Move(ThisFrameMove);
	}

	void RotateWielderTowardsDesiredSmashDirection() 
	{
		if (HasControl())
		{
			FVector SmashDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			if (!SmashDirection.IsNearlyZero())
			{
				const FVector SmashLocation = Player.GetActorLocation();
				FAutoAimLine Aim = GetAutoAimForTargetLine(
					Player,
					SmashLocation,
					SmashDirection,
					AutoAimDistance_MIN,
					AutoAimDistance_MAX,
					bCheckVisibility = true
				);

				if (Aim.AutoAimedAtActor != nullptr)
				{
					const FVector TargetPoint = Aim.AutoAimedAtComponent.GetWorldLocation();
					SmashDirection = (TargetPoint - SmashLocation).GetSafeNormal();
				}

				if (!SmashDirection.IsNormalized())
					SmashDirection.Normalize();

				MoveComp.SetTargetFacingDirection(
					SmashDirection,
					RotateWielderTowardsSmashDirection_Speed
				);
			}
		}
		else 
		{
			FHazeActorReplicationFinalized TargetParams;
			CrumbComp.GetCurrentReplicatedData(TargetParams);
			MoveComp.SetTargetFacingRotation(
				TargetParams.Rotation,
				RotateWielderTowardsSmashDirection_Speed
			);
		}
	}

}

















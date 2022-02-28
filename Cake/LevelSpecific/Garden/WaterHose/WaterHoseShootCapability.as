import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;

class UWaterHoseShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"WaterHose");
	default CapabilityTags.Add(n"WaterHoseShoot");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UWaterHoseComponent WaterHoseComp;
	UHazeCrumbComponent CrumbComp;

	//TArray<AActor> ActorsToIgnore;
	float CurrentDelayToNextShot = 0.f;

	FVector PlayerVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		WaterHoseComp = UWaterHoseComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!WaterHoseComp.bWaterHoseActive)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!WaterHoseComp.bWaterHoseActive)
		{
			if(HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}
		
		if(!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::AttemptWait_NoMovement);
		
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		DeactivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::AttemptWait_NoMovement);
		
		// We sync up the current container index when we quit so we are aligned as much as possible
		DeactivationParams.AddNumber(n"ContainerExitIndex", WaterHoseComp.ActiveWaterProjectileIndex);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentDelayToNextShot = 0;
		WaterHoseComp.bShooting = true;
		WaterHoseComp.bNextWaterIndexIsParent = true;
		WaterHoseComp.WaterHose.WaterSpawnEffect.SetVisibility(true);

		Player.SetCapabilityActionState(n"AudioStartShootWater", EHazeActionState::Active);	

		PlayerVelocity = MoveComp.GetVelocity();	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		const int TargetDeactivationIndex = DeactivationParams.GetNumber(n"ContainerExitIndex");
		if(WaterHoseComp.ActiveWaterProjectileIndex != TargetDeactivationIndex)
		{
			// Todo, Handle invalid shots
			int i = 0;
		}

		WaterHoseComp.ActiveWaterProjectileIndex = TargetDeactivationIndex;
		WaterHoseComp.bShooting = false;
		WaterHoseComp.WaterHose.WaterSpawnEffect.SetVisibility(false);

		Player.SetCapabilityActionState(n"AudioStopShootWater", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		PlayerVelocity = FMath::VInterpTo(PlayerVelocity, MoveComp.GetVelocity(), DeltaTime, 5);

		if(CurrentDelayToNextShot <= 0)
		{
			WaterHoseComp.ActivateNextProjectile(CurrentDelayToNextShot, MoveComp.WorldUp, PlayerVelocity);
			CurrentDelayToNextShot += WaterHoseComp.DelayBetweenProjectiles;
		}
		else
		{
			CurrentDelayToNextShot -= DeltaTime;
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString Out;
		Out += "Last Hit: ";
		if(WaterHoseComp.LastWaterHit.Actor != nullptr)
		{
			Out += WaterHoseComp.LastWaterHit.Actor;
		}
		else
		{
			Out += "None";
		}
		return Out;
	}

}

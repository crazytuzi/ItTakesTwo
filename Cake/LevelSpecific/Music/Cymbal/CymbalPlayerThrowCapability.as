import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Peanuts.Aiming.AutoAimStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalTags;
import Cake.LevelSpecific.Music.MusicTargetingComponent;
import Vino.Camera.Components.CameraUserComponent;

class UCymbalPlayerThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Cymbal");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCymbalComponent CymbalComp;
	UMusicTargetingComponent TargetingComp;
	ACymbal Cymbal;
	UCymbalSettings CymbalSettings;

	float CooldownElapsed = 0.0f;
	float CooldownStart = 0.85f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CymbalComp = UCymbalComponent::Get(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
		Cymbal = CymbalComp.CymbalActor;
		CymbalSettings = UCymbalSettings::GetSettings(Cymbal);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!CymbalComp.bCymbalEquipped)
			return EHazeNetworkActivation::DontActivate;

		if(CymbalComp.ThrowCooldownElapsed > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		// This is how we throw the cymbal when flying and aiming is not available
		if(IsActioning(n"ForceThrowCymbal"))
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		if (CymbalComp.bShieldActive)
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return EHazeNetworkActivation::DontActivate;
		
		if (!WasActionStarted(ActionNames::WeaponFire))
        	return EHazeNetworkActivation::DontActivate;

		if (!CymbalComp.bAiming && !CymbalComp.bThrowWithoutAim)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return CymbalComp.bCymbalEquipped;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		Player.PlayForceFeedback(CymbalComp.ThrowForceFeedback, false, true, NAME_None);
		UCymbalImpactComponent AutoAimTarget = Cast<UCymbalImpactComponent>(TargetingComp.CurrentTarget);
		if(AutoAimTarget != nullptr)
		{
			ActivationParams.AddObject(n"AutoAimTarget", AutoAimTarget);
		}
		else
		{
			const FVector ViewLocation = Player.ViewLocation;
			const FRotator ViewRotation = Player.ViewRotation;

			FVector TargetLocation;
			
			TArray<AActor> IgnoreActors;
			IgnoreActors.Add(Owner);
			IgnoreActors.Add(Cymbal);

			FHitResult Hit;
			System::LineTraceSingle(ViewLocation, ViewLocation + ViewRotation.ForwardVector * CymbalSettings.MovementDistanceMaximum, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
				
			if(Hit.bBlockingHit)
			{
				TargetLocation = Hit.ImpactPoint;
				ActivationParams.AddValue(n"CymbalDistance", Hit.Distance);
			}
			else
			{
				TargetLocation = ViewLocation + ViewRotation.ForwardVector * CymbalSettings.MovementDistanceMaximum;
				ActivationParams.AddValue(n"CymbalDistance", CymbalSettings.MovementDistanceMaximum);
			}

			const FVector TargetDirection = (TargetLocation - Player.ActorCenterLocation).GetSafeNormal();
			ActivationParams.AddVector(n"TargetLocation", TargetLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"CymbalShield", this);
		Owner.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.AddLocomotionAsset(CymbalComp.CymbalStrafe, this);

		Cymbal.AutoAimTarget = Cast<UCymbalImpactComponent>(ActivationParams.GetObject(n"AutoAimTarget"));

		bool bThrowCymbal = true;

		if(Cymbal.AutoAimTarget == nullptr)
		{
			FVector TargetLocation = ActivationParams.GetVector(n"TargetLocation");
			Cymbal.TargetLocation = TargetLocation;

			float CymbalDistance = ActivationParams.GetValue(n"CymbalDistance");
			bThrowCymbal = CymbalDistance > 500.0f;
		}

		//Cymbal.StartDirection = ActivationParams.GetVector(n"TargetDirection");
		CymbalComp.CurrentTarget = nullptr;
		Cymbal.HitObjects.Reset();

		// ThrowCymbal triggers the flow that detaches the Cymbal from the player and starts moving it.

		if(bThrowCymbal)
		{
			CymbalComp.ThrowCymbal();
			CymbalComp.bCymbalWasThrown = true;
			CymbalComp.bStartMoving = true;
			Cymbal.BP_OnCymbalThrow(Cymbal.CurrentTrailSystem);

			Player.SetCapabilityActionState(n"AudioCymbalThrow", EHazeActionState::ActiveForOneFrame);
			if(CymbalComp.ShouldPlayCatchAnimation())
			{
				MoveComp.SetAnimationToBeRequested(n"CymbalThrow");
			}
		}

		// Since we're throwing cymbal we want it to get shown if previoulsy hidden due to player camera overlap
		UCameraUserComponent User = UCameraUserComponent::Get(Owner);
		if (User != nullptr)
			User.UpdateHideOnOverlap.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearLocomotionAssetByInstigator(this);
		Owner.UnblockCapabilities(n"CymbalShield", this);
		Owner.UnblockCapabilities(MovementSystemTags::Jump, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		CymbalComp.ThrowCooldownElapsed -= DeltaTime;
	}
}

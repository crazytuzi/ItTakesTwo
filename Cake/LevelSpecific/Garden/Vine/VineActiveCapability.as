import Cake.LevelSpecific.Garden.Vine.VineComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Camera.Capabilities.CameraTags;

class UVineActiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"Vine");
	default CapabilityTags.Add(n"VineActive");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	// This needs to tick before vineaim capability, else the camera settings will break
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UPlayerHealthComponent HealthComp;
	UVineComponent VineComp;

	TArray<AActor> ActorsToIgnore;

	UVineImpactComponent ImpactPoint;
	UForceFeedbackEffect ActiveForceFeedbackEffect;
	FVector ActivationLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		VineComp = UVineComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp = UPlayerHealthComponent::Get(Player); 

		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::WeaponFire))
        	return EHazeNetworkActivation::DontActivate;

		if(!VineComp.bCanActivateVine)
			return EHazeNetworkActivation::DontActivate;

		if (!VineComp.CanAttachToTarget())
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (VineComp.VineActiveType != EVineActiveType::Inactive)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FVineHitResult VineHit;
		VineComp.GetVineImpact(VineHit);
		ActivationParams.AddStruct(n"Impact", VineHit);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"VineActive", true);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		FVineHitResult ReplicatedImpact;
		ActivationParams.GetStruct(n"Impact", ReplicatedImpact);
		VineComp.UpdateVineHitResultFromReplication(ReplicatedImpact);

		ImpactPoint = VineComp.VineImpactComponent;
		Player.ActivatePoint(ImpactPoint, this);
		VineComp.LockAttachmentPoint();

		VineComp.SetVisibility(true);
		VineComp.bAiming = true;

		VineComp.ApplyVineCameraSettings(0.1f);

		VineComp.SetVineAnimationType(EVineActiveType::PreExtending);
		Player.Mesh.HideBoneByName(n"BigLeaf1", EPhysBodyOp::PBO_None);	
		Niagara::SpawnSystemAttached(VineComp.SpawnEffect, Player.Mesh, VineComp.AttachPoint, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		ActivationLocation = Player.GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.SetAnimationToBeRequested(n"VineMovement");

		if(ImpactPoint != nullptr)
			ImpactPoint.VineDisconnected();
		
		SetMutuallyExclusive(n"VineActive", false);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);

		VineComp.bAiming = false;
		Player.Mesh.UnHideBoneByName(n"BigLeaf1");
		if(ActiveForceFeedbackEffect != nullptr)
		{
			Player.StopForceFeedback(ActiveForceFeedbackEffect, n"VineAttach");
			ActiveForceFeedbackEffect = nullptr;
		}
			
	 	Player.ClearPointOfInterestByInstigator(this);
	 	VineComp.VineActor.DeactivateVine();
	 	VineComp.SetVineAnimationType(EVineActiveType::Inactive);

		VineComp.SetVisibility(false);
		VineComp.ClearVineCameraSettings();
		VineComp.ClearVineHitResult();
		VineComp.ClearVineValues();
		Player.DeactivateCurrentPoint(this);
		ImpactPoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Player != nullptr)
		{
			if(Notification == n"VineConnected")
			{
				//const FVineHitResult VineHit = VineComp.GetVineHitResult();
				Player.SetCapabilityActionState(n"AudioVineAttach", EHazeActionState::ActiveForOneFrame);
				if(ImpactPoint != nullptr)
				{
					ImpactPoint.VineConnected();
					Niagara::SpawnSystemAtLocation(VineComp.VineActor.AttachImpactEffect, VineComp.GetTargetPoint());
				}
					
			}				
			else if(Notification == n"StartRetracting")
			{
				Player.ClearPointOfInterestByInstigator(this);	
				Player.SetCapabilityActionState(n"AudioVineDetach", EHazeActionState::ActiveForOneFrame);	
				VineComp.StartRetracting(ImpactPoint);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MoveComp.SetAnimationToBeRequested(n"VineMovement");
	
		if(HasControl())
		{
			// Update the widget for the current point
			FHazeQueriedActivationPoint ActiveQuery;
			Player.GetActivePoint(UVineImpactComponent::StaticClass(), ActiveQuery);
		}

		// This point is no longer valid and we are forced to deactivate it
		auto CurrentImpactPoint = VineComp.GetValidVineImpactComponent();
		if (VineComp.VineActiveType != EVineActiveType::Retracting && 
			(!VineComp.CanAttachToTarget() 
			|| CurrentImpactPoint != ImpactPoint))
		{
			TriggerNotification(n"StartRetracting");
		}

		if (VineComp.VineActiveType != EVineActiveType::Retracting
			&& VineComp.VineActiveType != EVineActiveType::PreExtending
			&& Player.GetActorLocation().DistSquared(ActivationLocation) > FMath::Square(50.f)) 
		{
			TriggerNotification(n"StartRetracting");
		}

		if(VineComp.VineActiveType == EVineActiveType::PreExtending && ActiveDuration >= VineComp.VineActivationDelayTime)
		{
			if(ImpactPoint.AttachedForceFeedback != nullptr)
			{
				ActiveForceFeedbackEffect = ImpactPoint.AttachedForceFeedback;
				Player.PlayForceFeedback(ActiveForceFeedbackEffect, ImpactPoint.bLoopAttachedForceFeedback, true, n"VineAttach");
			}
			else
			{
				ActiveForceFeedbackEffect = VineComp.AttachForceFeedback;
				Player.PlayForceFeedback(ActiveForceFeedbackEffect, false, true, n"VineAttach");
			}
				
			Player.PlayCameraShake(VineComp.AttachCamShake, 5.f);

			FHazePointOfInterest PoISettings;
			PoISettings.InitializeAsInputAssist();
			PoISettings.Blend.BlendTime = 1.f;
			PoISettings.FocusTarget.Component = ImpactPoint;
			Player.ApplyPointOfInterest(PoISettings, this);

			VineComp.VineActor.ActivateVineLocked();
			VineComp.SetVineAnimationType(EVineActiveType::Extending);
		}
		else if(VineComp.VineActiveType == EVineActiveType::Extending)
		{
			VineComp.UpdateVineTraceHitResult(ImpactPoint, IsDebugActive());
			if(!VineComp.UpdateExtending(DeltaTime))
			{
				// We have reached the target
				VineComp.SetVineAnimationType(EVineActiveType::ActiveAndLocked);
				TriggerNotification(n"VineConnected");
				Player.SetCapabilityActionState(n"AudioVineImpact", EHazeActionState::ActiveForOneFrame);
			}
		}
		else if(VineComp.VineActiveType == EVineActiveType::ActiveAndLocked)
		{
			VineComp.UpdateVineTraceHitResult(ImpactPoint, IsDebugActive());
			const bool bStillHasPoint = VineComp.GetValidVineImpactComponent() == ImpactPoint;
			if(bStillHasPoint)
			{
				VineComp.VineActor.UpdateLockedOn();
				const FVector ImpactDelta = (VineComp.GetTargetPoint() - VineComp.VineActor.GetStartLocation());
				const FVector FaceDirection = ImpactDelta.ConstrainToPlane(Player.GetMovementWorldUp()).GetSafeNormal();

				if(FaceDirection.IsUnit())
				{
					MoveComp.SetTargetFacingDirection(FaceDirection);
				}
			}
			else
			{
				TriggerNotification(n"StartRetracting");
			}

			if(HasControl() && VineComp.VineActiveType == EVineActiveType::ActiveAndLocked)
			{
				if(!IsActioning(ActionNames::WeaponFire) || IsActioning(n"ForceVineRelease") || !bStillHasPoint)
				{
					TriggerNotification(n"StartRetracting");
				}
			}
		}
		else if(VineComp.VineActiveType == EVineActiveType::Retracting)
		{
			if(!VineComp.UpdateRetracting(DeltaTime))
			{
				// We have reached the target
				VineComp.SetVineAnimationType(EVineActiveType::Inactive);
			}
		}

		VineComp.CurrentActiveTime += DeltaTime;
	}
}
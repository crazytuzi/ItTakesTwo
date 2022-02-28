import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCarWindupCharacterAnimComponent;

class UPullbackCarPlayerDrivingCarCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PullbackCarPlayerDrivingCarCapability");
	default CapabilityTags.Add(CapabilityTags::Input);

	default CapabilityDebugCategory = n"PullbackCarPlayerDrivingCarCapability";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 99;

	AHazePlayerCharacter Player;
	APullbackCar PullbackCar;
	UPullbackCarWindupCharacterAnimComponent PullBackComponent;
	UHazeCameraComponent PlayerCamera;
	// bool bDeactivatedByCancel = false;

	bool bHasShowedCancelPrompt = false;

	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature;

	UPROPERTY()
	UHazeLocomotionFeatureBase MayFeature;

	UPROPERTY()
	FText HonkTutText;

	UPROPERTY()
	UForceFeedbackEffect HonkForceFeedback;

	UHazeLocomotionFeatureBase FeatureToUse; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PullBackComponent = UPullbackCarWindupCharacterAnimComponent::Get(Player);
		ensure(PullBackComponent != nullptr);
		FeatureToUse = Player == Game::GetCody() ? CodyFeature : MayFeature;
		Player.AddLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Wait for full sync
		if(PullbackCar != nullptr)
			return EHazeNetworkActivation::DontActivate;

        if (PullBackComponent.PullbackCar == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!PullBackComponent.bPlayerDrivingCar)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (PullBackComponent.PullbackCar == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!PullBackComponent.bPlayerDrivingCar)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PullbackCar = PullBackComponent.PullbackCar;
		Player.BlockCapabilities(CapabilityTags::CollisionAndOverlap, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this, n"PullbackCarDrive");
		Player.AttachToComponent(PullbackCar.DriverAttachComp, n"", EAttachmentRule::SnapToTarget);
		Player.OtherPlayer.DisableOutlineByInstigator(this);
		PullbackCar.WindupPullcarInteractComp.DisableForPlayer(Player, n"InOtherInteraction");
		//PullbackCar.OnPullbackCarWasDestroyed.AddUFunction(this, n"CarWasDestroyed");
		// bDeactivatedByCancel = false;
		// bHasShowedCancelPrompt = false;

		FHazeCameraBlendSettings Blend;
		Player.ApplyCameraSettings(PullbackCar.DriverCamSettings, Blend, this, EHazeCameraPriority::Medium);
		//InteractedPlayer.BlockCapabilities(CapabilityTags::CollisionAndOverlap, this);

		PlayerCamera = Player.GetCurrentlyUsedCamera();
		if (PlayerCamera != nullptr)
			PlayerCamera.CameraCollisionParams.AdditionalIgnoreActors.AddUnique(PullbackCar);

		FTutorialPrompt HonkPrompt;
		HonkPrompt.DisplayType = ETutorialPromptDisplay::Action;
		HonkPrompt.Action = n"MovementJump";
		HonkPrompt.Text = HonkTutText;
		ShowTutorialPrompt(Player, HonkPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
		
		if(PullbackCar != nullptr)
		{
			PullbackCar.WindupPullcarInteractComp.EnableForPlayerAfterFullSyncPoint(Player, n"InOtherInteraction");
			if (PlayerCamera != nullptr)
				PlayerCamera.CameraCollisionParams.AdditionalIgnoreActors.Remove(PullbackCar);

			// Always set honk from network
			if(HasControl())
			{
				PullbackCar.NetSetHonking(false);
			}

			PullbackCar.DriverSteeringDirection = 0;
		}

		Player.UnblockCapabilities(CapabilityTags::CollisionAndOverlap, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);	
		Player.OtherPlayer.EnableOutlineByInstigator(this);
		//PullbackCar.OnPullbackCarWasDestroyed.Clear();
		RemoveCancelPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, this);
		

		FHazeJumpToData JumpData;
		FTransform JumpTransform = Player.GetActorTransform();
		FVector Loc = JumpTransform.Location + FVector(0.f, 0.f, 10.f); // Added a small offset on Z to avoid false blocking hits on the floor
		Loc += Player.ActorRightVector * 300.f;
		
		if (IsActioning(n"ManuallyExitCar"))
		{
			TArray<AActor> ActorsToIgnore;
			ActorsToIgnore.Add(Game::GetCody());
			FHitResult PlayerTraceHit;
			System::CapsuleTraceSingle(Loc + FVector(0.f, 0.f, Player.CapsuleComponent.GetScaledCapsuleHalfHeight()), Loc + FVector(0.f, 0.f, Player.CapsuleComponent.GetScaledCapsuleHalfHeight()), 
			Player.CapsuleComponent.GetScaledCapsuleRadius(), Player.CapsuleComponent.GetScaledCapsuleHalfHeight(), ETraceTypeQuery::Visibility, false,  ActorsToIgnore, EDrawDebugTrace::None, PlayerTraceHit, true);
			
			if (!PlayerTraceHit.bBlockingHit)
			{
				JumpTransform.Location = Loc;
				JumpData.Transform =  JumpTransform;
				JumpTo::ActivateJumpTo(Player, JumpData);
			}
			else
			{
				Loc = JumpTransform.Location; 
				Loc += Player.ActorRightVector * -300.f;
				System::CapsuleTraceSingle(Loc + FVector(0.f, 0.f, Player.CapsuleComponent.GetScaledCapsuleHalfHeight()), Loc + FVector(0.f, 0.f, Player.CapsuleComponent.GetScaledCapsuleHalfHeight()), 
				Player.CapsuleComponent.GetScaledCapsuleRadius(), Player.CapsuleComponent.GetScaledCapsuleHalfHeight(), ETraceTypeQuery::Visibility, false,  ActorsToIgnore, EDrawDebugTrace::None, PlayerTraceHit, true);
				
				if (!PlayerTraceHit.bBlockingHit)
				{
					JumpTransform.Location = Loc;
					JumpData.Transform =  JumpTransform;
					JumpTo::ActivateJumpTo(Player, JumpData);
				}
				// If neither left or right location of the car is free from blocking hits, skip JumpTo.
			}
		}

		Sync::FullSyncPoint(this, n"RemoveDriveSheet");
	}

	UFUNCTION()
	void RemoveDriveSheet()
	{
		if(Player == nullptr)
			return;

		if(PullbackCar == nullptr)
			return;

		Player.RemoveCapabilitySheet(PullbackCar.DriverSheet, PullbackCar);
		PullbackCar = nullptr;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"PullBackCarSit";
		PullbackCar.PlayerDrivingCar.RequestLocomotion(AnimRequest);	

		FVector2D LeftStickInput;
		LeftStickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		PullbackCar.DriverSteeringDirection = LeftStickInput.X;

		if(PullbackCar.CanManuallyExitAsDriver())
		{
			if(IsActioning(ActionNames::Cancel) && HasControl())
			{
				PullbackCar.NetRequestPlayerExitDriverInteraction();
			}
			else if(!bHasShowedCancelPrompt)
			{
				bHasShowedCancelPrompt = true;
				ShowCancelPrompt(Player, this);
			}
		}
		else if(bHasShowedCancelPrompt)
		{
			bHasShowedCancelPrompt = false;
			RemoveCancelPromptByInstigator(Player, this);
		}

		if(HasControl())
		{
			const bool bWantToHonk = IsActioning(ActionNames::MovementJump) && PullbackCar.CanHonk();
			if (PullbackCar.bPlayerIsHonking != bWantToHonk)
			{
				PullbackCar.NetSetHonking(bWantToHonk);

				if(bWantToHonk)
				{
					if (WasActionStarted(ActionNames::MovementJump))
						Player.PlayForceFeedback(HonkForceFeedback, false, true, n"Honk");

					Player.SetFrameForceFeedback(0.05f, 0.05f);
				}
			}
		}
	}
}
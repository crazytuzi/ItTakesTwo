import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent;
import Peanuts.Audio.AudioStatics;

class UCannonCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"Cannon");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	bool bLaunchedPlayer = false;
	
	UCannonToShootMarblePlayerComponent CannonComponent;
	UHazeCrumbComponent CrumbComp;

	bool bIsInMh;
	bool bHasQuit = false;
	bool bShowTutorial = true;
	float TutorialTimer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
		CannonComponent = UCannonToShootMarblePlayerComponent::Get(Player);
		CrumbComp = UHazeCrumbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Cannon != nullptr)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// The shooting capability will block this capability
		// Making sure everything happens in the correct order
		if(CannonComponent.bIsBeeingShot)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (bHasQuit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);
		PlayEnterAnimation();
		
		FHazeCameraBlendSettings CamBlendSettings;
		CamBlendSettings.BlendTime = 2.f;
		Player.ActivateCamera(Cannon.Camera, CamBlendSettings, Instigator = this);
		Player.GetOtherPlayer().DisableOutlineByInstigator(this);
		HazeAudio::SetPlayerPanning(Cannon.HazeAkComp, Player);
		Cannon.HazeAkComp.HazePostEvent(Cannon.PlayMovementAudioEvent);

		ShowTutorial();

		if (Cannon.bAllowCancel)
			ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Cannon.bPlayerReadyToBeShot = false;
		
		RemoveTutorialPromptByInstigator(Player, this);
	
		Player.DeactivateCameraByInstigator(this, 0.33f);
		Player.ClearCameraSettingsByInstigator(this);
		Cannon.ReleaseCannon();
		Player.StopAllSlotAnimations();
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.GetOtherPlayer().EnableOutlineByInstigator(this);
		Cannon.HazeAkComp.HazePostEvent(Cannon.StopMovementAudioEvent);

		if(Cannon != nullptr)
		{
			if (Cannon.bAllowCancel)
				RemoveCancelPromptByInstigator(Player, this);
				
			if (!CannonComponent.bIsBeeingShot)
			{
				if(bHasQuit)
					Player.TeleportActor(Cannon.LeaveCannonTeleportTarget.WorldLocation, Cannon.LeaveCannonTeleportTarget.WorldRotation);

				Cannon.RemoveCapabilityRequest(Player);
				CannonComponent.CannonActor = nullptr;	
			}
		}

		bIsInMh = false;
		bHasQuit = false;		
	}

	void PlayEnterAnimation()
	{
		FHazePlaySlotAnimationParams AnimSettings;
		FHazePlaySlotAnimationParams CannonSlotAnimParams;
		
		const auto& Data = CannonComponent.ShootCanonData;

		AnimSettings.Animation = Data.EnterAnimation;
		CannonSlotAnimParams.Animation =  Data.CannonEnterAnimation;

		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnEnterAnimDone;
		OnEnterAnimDone.BindUFunction(this, n"EnteredCannon");
		Player.PlaySlotAnimation(OnBlendedIn, OnEnterAnimDone, AnimSettings);
		Cannon.SkelMesh.PlaySlotAnimation(CannonSlotAnimParams);
	}

	void ShowTutorial()
	{
		if (!bShowTutorial)
			return; 

		const auto& Data = CannonComponent.ShootCanonData;
		FTutorialPrompt Prompt;
		Prompt.Action = AttributeVectorNames::MovementRaw;
		Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;
		Prompt.MaximumDuration = 6;
		Prompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
		Prompt.Text = Data.TutorialText;
		
		ShowTutorialPrompt(Player, Prompt, this);
		
	}

	UFUNCTION(NotBlueprintCallable)
	protected void EnteredCannon()
	{
		Player.AttachToComponent(Cannon.SkelMesh, n"CannonMuzzle", AttachmentRule = EAttachmentRule::KeepWorld);
		FHazePlaySlotAnimationParams Params;
		Params.bLoop = true;
		Params.BlendTime = 0;

		const auto& Data = CannonComponent.ShootCanonData;
		Params.Animation = Data.IdleAnimation;

		Player.PlaySlotAnimation(Params);
		bIsInMh = true;

		Cannon.EnableShootCannon(Player.GetOtherPlayer());
	}

    void CheckIfShouldDeactive() const
    {
		if(!HasControl())
			return;

		if(!Cannon.bAllowCancel || !IsActioning(ActionNames::Cancel))
			return;

		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbTriggerExit"), FHazeDelegateCrumbParams());
    }

	UFUNCTION(NotBlueprintCallable)
	void CrumbTriggerExit(const FHazeDelegateCrumbData& CrumbData)
	{
		bHasQuit = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bIsInMh)
			return;

		FVector InputVector = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		Cannon.XAxis = InputVector.X;

		Cannon.YAxis = InputVector.Y;

		if (FMath::Abs(InputVector.X) > 0.1 )
		{
			TutorialTimer += DeltaTime;

			if (TutorialTimer > 1)
			{
				RemoveTutorialPromptByInstigator(Player, this);
				bShowTutorial = false;
			}
		}

		
		CheckIfShouldDeactive();

		if (Cannon.bShowTrajectory)
			DrawCannonTrajectory();
	}

	void DrawCannonTrajectory()
	{
		FHitResult hitresult;
		TArray<AActor> ActorArray;
		FHitResult Hit;
		ActorArray.Add(Cannon);
		FVector TraceDir = Cannon.ShootDirection.ForwardVector;
		TraceDir = Math::ConstrainVectorToPlane(TraceDir, FVector::UpVector);
		System::LineTraceSingle(Cannon.ShootDirection.WorldLocation, Cannon.ShootDirection.WorldLocation + TraceDir * 50000, ETraceTypeQuery::Visibility, false, ActorArray, EDrawDebugTrace::None, Hit, true);
		float Distance = Hit.Location.Distance(Cannon.ShootDirection.WorldLocation);
		Distance -= 1000;

		// Distance = FMath::Clamp(Distance, 2000.f, 10000.f);

		Cannon.TrajectoryDrawer.DrawTrajectory(Cannon.ShootDirection.WorldLocation, Distance, Cannon.ShootDirection.ForwardVector * 130.f, 1.f, 15.0f, FLinearColor::White, nullptr, 6, 0.65f);
	}

	ACannonToShootMarbleActor GetCannon() const property
	{
		return CannonComponent.CannonActor;
	}
};
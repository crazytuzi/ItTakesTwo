import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;
import Vino.Interactions.Widgets.InteractionWidgetsComponent;
import Vino.Tutorial.TutorialStatics;

class UPlayerGrabFlyingBombCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"ClockworkInputCapability";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;
	AClockworkBird MountedBird;
	UBirdFlyingBombTrackerComponent TrackerComp;
	UInteractionWidgetsComponent WidgetComp;

	AFlyingBomb NearbyBomb;

	bool bAimTutorial = false;
	bool bFireTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TrackerComp = UBirdFlyingBombTrackerComponent::GetOrCreate(Owner);
		WidgetComp = UInteractionWidgetsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{	
		MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		UpdateNearbyBomb();
	}

	void UpdateNearbyBomb()
	{
		if (MountedBird == nullptr || TrackerComp.HeldBomb != nullptr || IsActive())
		{
			NearbyBomb = nullptr;
			return;
		}

		AFlyingBomb GrabBomb;
		float BestScore = MAX_flt;
		for (auto Bomb : TrackerComp.NearbyBombs)
		{
			if (Bomb.CurrentState != EFlyingBombState::Idle)
				continue;
			if (Bomb.HeldByBird != nullptr)
				continue;

			float DistanceSQ = Bomb.ActorLocation.DistSquared(MountedBird.ActorLocation);
			float WidgetDistSQ = FMath::Square(Bomb.GrabWidgetDistance);
			if (DistanceSQ > WidgetDistSQ)
				continue;

			WidgetComp.ShowInteractionWidgetThisFrame(
				Bomb.GrabWidgetRoot,
				bAvailable = true
			);

			float GrabDistSQ = FMath::Square(Bomb.GrabDistance);
			if (DistanceSQ < GrabDistSQ)
			{
				FVector ToBird = Bomb.ActorLocation - MountedBird.ActorLocation;
				float DotToBirdVelocity = ToBird.GetSafeNormal().DotProduct(MountedBird.ActorVelocity.GetSafeNormal());

				float GrabScore = DistanceSQ;
				if (DotToBirdVelocity < 0.f)
				{
					if (DistanceSQ > FMath::Square(Bomb.GrabBehindDistance))
						continue;
					GrabScore *= 100.f;
				}

				if (GrabScore < BestScore)
				{
					BestScore = GrabScore;
					GrabBomb = Bomb;
				}
			}
		}

		NearbyBomb = GrabBomb;
		if (NearbyBomb != nullptr)
		{
			WidgetComp.ShowInteractionWidgetThisFrame(
				NearbyBomb.GrabWidgetRoot,
				bAvailable = true,
				bFocused = true
			);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (NearbyBomb == nullptr || MountedBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (!WasActionStarted(ActionNames::InteractionTrigger))
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
        if (TrackerComp.HeldBomb == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (WasActionStarted(ActionNames::WeaponFire) && Owner.IsAnyCapabilityActive(n"ClockworkBirdAim") && TrackerComp.HeldBomb.HeldByBird == MountedBird)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        if (TrackerComp.HeldBomb.HeldByBird != nullptr && TrackerComp.HeldBomb.HeldByBird != MountedBird)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        if (TrackerComp.HeldBomb.LocalWantHeldByBird == nullptr && TrackerComp.HeldBomb.HeldByBird != MountedBird)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Bomb", NearbyBomb);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto Bomb = Cast<AFlyingBomb>(ActivationParams.GetObject(n"Bomb"));
		TrackerComp.HeldBomb = Bomb;
		Bomb.TryPickupBomb(MountedBird);

		Player.ApplyCameraSettings(
			MountedBird.CameraSettings_HeldBomb, 
			MountedBird.CameraSettingsBlend_HeldBomb, 
			Instigator = this, Priority = EHazeCameraPriority::Medium);
	}

	void ShowAimTutorial()
	{
		FTutorialPrompt AimPrompt;
		AimPrompt.Action = ActionNames::WeaponAim;
		AimPrompt.DisplayType = ETutorialPromptDisplay::Action;
		AimPrompt.Text = NSLOCTEXT("ClockworkBird", "AimTutorialPrompt", "Aim");
		ShowTutorialPrompt(Player, AimPrompt, this);
	}

	void ShowFireTutorial()
	{
		FTutorialPrompt DropPrompt;
		DropPrompt.Action = ActionNames::WeaponFire;
		DropPrompt.DisplayType = ETutorialPromptDisplay::Action;
		DropPrompt.Text = NSLOCTEXT("ClockworkBird", "LaunchBombTutorialPrompt", "Throw Bomb");
		ShowTutorialPrompt(Player, DropPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.ClearCameraSettingsByInstigator(this);

		if (TrackerComp.HeldBomb != nullptr)
		{
			TrackerComp.FollowDroppedBomb = TrackerComp.HeldBomb;
			TrackerComp.HeldBomb.SetCapabilityActionState(n"DropBomb", EHazeActionState::Active);
			TrackerComp.HeldBomb = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		bool bShouldShowFire = false;
		bool bShouldShowAim = false;

		if (Owner.IsAnyCapabilityActive(n"ClockworkBirdAim"))
		{
			bShouldShowFire = true;
		}
		else
		{
			bShouldShowAim = true;
		}

		if (bShouldShowAim != bAimTutorial
			|| bShouldShowFire != bFireTutorial)
		{
			RemoveTutorialPromptByInstigator(Player, this);

			if (bShouldShowAim)
				ShowAimTutorial();
			if (bShouldShowFire)
				ShowFireTutorial();

			bAimTutorial = bShouldShowAim;
			bFireTutorial = bShouldShowFire;
		}
	}
}
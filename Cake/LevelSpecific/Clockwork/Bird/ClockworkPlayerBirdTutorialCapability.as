import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;

class UClockworkPlayerBirdTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"ClockworkInputCapability";
	
	AHazePlayerCharacter Player;
	UBirdFlyingBombTrackerComponent TrackerComp;

	bool bGroundTutorial = false;
	bool bAirTutorial = false;
	bool bLandTutorial = false;

	float TimerGroundTutorial = 0.f;
	float TimerAirTutorial = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TrackerComp = UBirdFlyingBombTrackerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
        if (MountedBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (Player.HasControl() && !MountedBird.HasControl())
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		if (MountedBird == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MountedBird.PlayerIsUsingBird(Player))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	void ShowGroundTutorial()
	{
		FTutorialPrompt FlyPrompt;
		FlyPrompt.Action = ActionNames::MovementJump;
		FlyPrompt.DisplayType = ETutorialPromptDisplay::Action;
		FlyPrompt.Text = NSLOCTEXT("ClockworkBird", "FlyTutorialPrompt", "Fly");
		ShowTutorialPrompt(Player, FlyPrompt, this);

		FTutorialPrompt DismountPrompt;
		DismountPrompt.Action = ActionNames::Cancel;
		DismountPrompt.DisplayType = ETutorialPromptDisplay::Action;
		DismountPrompt.Text = NSLOCTEXT("ClockworkBird", "DismountTutorialPrompt", "Dismount");
		ShowTutorialPrompt(Player, DismountPrompt, this);
	}

	void ShowAirTutorial(bool bCanLand)
	{
		FTutorialPrompt FlapPrompt;
		FlapPrompt.Action = ActionNames::MovementJump;
		FlapPrompt.DisplayType = ETutorialPromptDisplay::Action;
		FlapPrompt.Text = NSLOCTEXT("ClockworkBird", "FlyUpTutorialPrompt", "Fly Up");
		ShowTutorialPrompt(Player, FlapPrompt, this);

		if (bCanLand)
		{
			FTutorialPrompt LandPrompt;
			LandPrompt.Action = ActionNames::MovementCrouch;
			LandPrompt.DisplayType = ETutorialPromptDisplay::Action;
			LandPrompt.Text = NSLOCTEXT("ClockworkBird", "LandTutorialPrompt", "Land");
			ShowTutorialPrompt(Player, LandPrompt, this);
		}
		else
		{
			FTutorialPrompt LandPrompt;
			LandPrompt.Action = ActionNames::MovementCrouch;
			LandPrompt.DisplayType = ETutorialPromptDisplay::Action;
			LandPrompt.Text = NSLOCTEXT("ClockworkBird", "FlyDownTutorialPrompt", "Fly Down");
			ShowTutorialPrompt(Player, LandPrompt, this);
		}

		FTutorialPrompt DashPrompt;
		DashPrompt.Action = ActionNames::MovementDash;
		DashPrompt.DisplayType = ETutorialPromptDisplay::Action;
		DashPrompt.Text = NSLOCTEXT("ClockworkBird", "DashTutorialPrompt", "Dash");
		ShowTutorialPrompt(Player, DashPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimerGroundTutorial = 0.f;
		TimerAirTutorial = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));

		bool bShouldShowGround = false;
		bool bShouldShowAir = false;
		bool bShouldShowLand = false;

		if (!MountedBird.bIsFlying)
		{
			TimerGroundTutorial += DeltaTime;
			if (TimerGroundTutorial < 10.f)
				bShouldShowGround = true;
		}
		else if (TrackerComp.HeldBomb == nullptr && !MountedBird.bIsLaunching)
		{
			TimerGroundTutorial = 10.f;
			TimerAirTutorial += DeltaTime;
			if (TimerAirTutorial < 10.f)
			{
				bShouldShowAir = true;
				bShouldShowLand = MountedBird.bCanLand;
			}
		}
		else if (TrackerComp.HeldBomb != nullptr)
		{
			TimerAirTutorial = 10.f;
		}


		if (bShouldShowGround != bGroundTutorial
			|| bShouldShowAir != bAirTutorial
			|| bShouldShowLand != bLandTutorial)
		{
			RemoveTutorialPromptByInstigator(Player, this);

			if (bShouldShowGround)
				ShowGroundTutorial();
			if (bShouldShowAir)
				ShowAirTutorial(bShouldShowLand);

			bGroundTutorial = bShouldShowGround;
			bAirTutorial = bShouldShowAir;
			bLandTutorial = bShouldShowLand;
		}
	}
}
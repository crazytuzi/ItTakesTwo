import Vino.Tutorial.TutorialStatics;
import Rice.PauseMenu.PauseMenuSingleton;

UFUNCTION()
void AddInvertSteeringTutorial(AHazePlayerCharacter Player)
{
	Player.AddCapability(UInvertSteeringTutorialCapability::StaticClass());
}

UFUNCTION()
void RemoveInvertSteeringTutorial(AHazePlayerCharacter Player)
{
	Player.RemoveCapability(UInvertSteeringTutorialCapability::StaticClass());
}

// Level designers, feel free to tweak these settings
UCLASS(Meta = (ComposeSettingsOnto = "UInvertSteeringTutorialSettings"))
class UInvertSteeringTutorialSettings : UHazeComposableSettings
{
	// When stick has been turned upwards for this long and downwards for this long, we trigger tutorial
	UPROPERTY()
	float StartTutorialInputDuration = 0.5f;

	UPROPERTY()
	float TimeDilationBlendInDuration = 1.f;

	UPROPERTY()
	float TimeDilationBlendOutDuration = 0.5f;
}

class UInvertSteeringTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Tutorial";

	AHazePlayerCharacter Player;
	UInvertSteeringTutorialSettings Settings;
	FName InvertSteeringPitchName;
	FString KeepDefaultValue;
	FString ChangedValue;

	float UpwardsInputDuration = 0.f;
	float DownwardsInputDuration = 0.f;
	float TutorialStartTime = 0.f;
	float DeactivationTime = 0.f;
	bool bPressedCancel = false;
	bool bTutorialCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UInvertSteeringTutorialSettings::GetSettings(Owner);
		InvertSteeringPitchName = (Player.IsCody()) ? n"InvertSteeringCody": n"InvertSteeringMay";
	}

	// We use crumbs sine we want to make time dilation match crumb trail.
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (bTutorialCompleted)
			return EHazeNetworkActivation::DontActivate;	
		if (Player.HasSetSteeringPitchInverted())
			return EHazeNetworkActivation::DontActivate;	
		if (DeactivationTime != 0.f)
			return EHazeNetworkActivation::DontActivate; // Don't reactivate while deactivating	
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if (bTutorialCompleted)
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Player.HasSetSteeringPitchInverted())
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// In case we change the default, we wont have to change anything here
		if (Player.IsSteeringPitchInverted())
		{
			KeepDefaultValue = "On";
			ChangedValue = "Off";
		}
		else
		{
			KeepDefaultValue = "Off";
			ChangedValue = "On";
		}

		TutorialStartTime = 0.f;
		DeactivationTime = 0.f;
		UpwardsInputDuration = 0.f;
		DownwardsInputDuration = 0.f;
		bPressedCancel = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void CrumbStartTutorial(const FHazeDelegateCrumbData& CrumbData)
	{
		TutorialStartTime = Time::GetRealTimeSeconds();

		FTutorialPrompt KeepPrompt;
		KeepPrompt.Action = ActionNames::GUIPauseMenu;
		KeepPrompt.DisplayType = ETutorialPromptDisplay::Action;
		KeepPrompt.Text = NSLOCTEXT("SteeringInvertTutorial", "SteeringInvertKeepTutorialPrompt", "Open options menu to change inverted steering.");
		ShowTutorialPrompt(Player, KeepPrompt, this);

		ShowCancelPrompt(Player, this);

		UPauseMenuSingleton PauseMenu = UPauseMenuSingleton::Get();
		PauseMenu.OnClosed.AddUFunction(this, n"OnMenuClosed");
		PauseMenu.OnOptionsClosed.AddUFunction(this, n"OnMenuClosed");
		PauseMenu.PrepareForOptionsMenu(InvertSteeringPitchName);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMenuClosed()
	{
		if (bTutorialCompleted)
			return;

		// We assume player wants to keep current value since they may not have actually set something.	
		GameSettings::SetGameSettingsValue(InvertSteeringPitchName, Player.IsSteeringPitchInverted() ? "On" : "Off");
		bTutorialCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((TutorialStartTime == 0.f) && HasControl())
		{
			// Start tutorial when we've given some input upwards and some downwards
			float VerticalSteeringInput = GetAttributeVector(AttributeVectorNames::LeftStickRaw).Y;
			if (Player.IsSteeringPitchInverted())
				VerticalSteeringInput *= -1.f;
			if (VerticalSteeringInput > 0.01f)
				UpwardsInputDuration += DeltaTime;
			if (VerticalSteeringInput < -0.01f)
				DownwardsInputDuration += DeltaTime;

			if ((UpwardsInputDuration > Settings.StartTutorialInputDuration) && 
				(DownwardsInputDuration > Settings.StartTutorialInputDuration))
			{
				UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Owner);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbStartTutorial"), FHazeDelegateCrumbParams());
			} 	
		}

		// Is tutorial in progress?
		if (TutorialStartTime > 0.f)
		{
			float Alpha = 1.f;
			if (Settings.TimeDilationBlendInDuration > 0.f)
				Alpha = FMath::Clamp(Time::GetRealTimeSince(TutorialStartTime) / Settings.TimeDilationBlendInDuration, 0.f, 1.f);
			Time::SetWorldTimeDilation(FMath::EaseInOut(1.f, 0.f, Alpha, 2.f));	

			if (HasControl())
			{
				// Has player cancelled?
				if (WasActionStarted(ActionNames::GUICancel))
					bPressedCancel = true;

				if (bPressedCancel && WasActionStopped(ActionNames::GUICancel))
				{
					// We assume player wants to keep default value.	
					GameSettings::SetGameSettingsValue(InvertSteeringPitchName, KeepDefaultValue);
					bTutorialCompleted = true;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DeactivationTime = Time::GetRealTimeSeconds();
		RemoveTutorialPromptByInstigator(Player, this);	
		RemoveCancelPromptByInstigator(Player, this);

		UPauseMenuSingleton PauseMenu = UPauseMenuSingleton::Get();
		PauseMenu.OnClosed.Unbind(this, n"OnPauseMenuClosed");
		PauseMenu.OnOptionsClosed.Unbind(this, n"OnPauseMenuClosed");
		PauseMenu.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && (DeactivationTime != 0.f))
		{
			float Alpha = 0.f;
			if (Settings.TimeDilationBlendOutDuration > 0.f)
				Alpha = FMath::Clamp(Time::GetRealTimeSince(DeactivationTime) / Settings.TimeDilationBlendOutDuration, 0.f, 1.f);
			Time::SetWorldTimeDilation(FMath::EaseInOut(0.f, 1.f, Alpha, 2.f));	
			
			if (Alpha == 1.f)
			{
				TutorialStartTime = 0.f;
				DeactivationTime = 0.f;	
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		// Make sure time dilation has been restored
		if (TutorialStartTime != 0.f)
		 	Time::SetWorldTimeDilation(1.f);			
	}
}

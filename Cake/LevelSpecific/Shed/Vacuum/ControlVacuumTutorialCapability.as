import Cake.LevelSpecific.Shed.Vacuum.ControlVacuumCapability;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;

class UControlVacuumTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UPROPERTY()
	UVacuumVOBank Bank;

	AHazePlayerCharacter Player;

	bool bTutorialCompleted = false;
	bool bBarkPlayed = false;

	float TimeSpentDoingInput = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(UControlVacuumCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (bTutorialCompleted)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(UControlVacuumCapability::StaticClass()))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bTutorialCompleted)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeSpentDoingInput = 0.f;

		FTutorialPrompt Prompt;
		Prompt.Action = AttributeVectorNames::MovementRaw;
		Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;
		ShowTutorialPrompt(Player, Prompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		if (MovementInput.Size() > 0.25f)
		{
			TimeSpentDoingInput += DeltaTime;
		}

		if (TimeSpentDoingInput >= 1.f && !bBarkPlayed)
			NetPlayBark();

		if (TimeSpentDoingInput >= 2.f)
			bTutorialCompleted = true;
	}

	UFUNCTION(NetFunction)
	void NetPlayBark()
	{
		bBarkPlayed = true;
		if (Player.IsMay())
			PlayFoghornVOBankEvent(Bank, n"FoghornDBShedVacuumHoseFirstMay");
		else if (Player.IsCody())
			PlayFoghornVOBankEvent(Bank, n"FoghornDBShedVacuumHoseFirstCody");
	}
}
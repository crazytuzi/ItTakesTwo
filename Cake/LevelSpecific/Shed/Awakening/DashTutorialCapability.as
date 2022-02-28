import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Dash.CharacterDashCapability;
import Vino.Pickups.PlayerPickupComponent;
class UDashTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FText Dash;

	bool bHasDashed = false;
	bool bIsDashing = false;
	int DashCount = 0;
	UPlayerPickupComponent PickupComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		PickupComp = UPlayerPickupComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(UCharacterDashCapability::StaticClass()) ||
			!MoveComp.IsGrounded() ||
			DashCount > 0)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if (UPlayerPickupComponent::Get(Player).CurrentPickup != nullptr)
		{
			return EHazeNetworkActivation::DontActivate;	
		}

		if (IsActioning(n"ShowDashTutorial"))
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
        else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ShowDashTutorial") || !Player.MovementComponent.IsGrounded() || Player.IsAnyCapabilityActive(UCharacterDashCapability::StaticClass()) || DashCount > 1)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		if (PickupComp.CurrentPickup != nullptr)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;	
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ShowTutorial();
	}

	void ShowTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);

		FTutorialPrompt PromptOne;
		PromptOne.Action = ActionNames::MovementDash;
		PromptOne.DisplayType = ETutorialPromptDisplay::Action;
		PromptOne.Mode = ETutorialPromptMode::Default;
		PromptOne.Text = Dash;
		ShowTutorialPrompt(Player, PromptOne, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterDashCapability::StaticClass()))
		{
			if (bIsDashing == false)
			{
				DashCount++;
			}

			bHasDashed = true;
			bIsDashing = true;
		}
		else
		{
			bIsDashing = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterDashCapability::StaticClass()))
		{
			bHasDashed = true;
		}
	}
}
import Cake.LevelSpecific.PlayRoom.GoldBerg.TrainStation.Matrioshka.MatrioShkaActor;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
class UMatruoshkaCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	AMatrioshkaActor Doll;
	float TimeShaking = 0;

	bool bIsShowingTutorial;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"Doll") != nullptr)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION()
	void ShowTutorial()
	{
		if (bIsShowingTutorial)
			return;

		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::MovementDash;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.MaximumDuration = 3.f;
		
		ShowTutorialPrompt(Player, Prompt, this);
		bIsShowingTutorial = true;
	}

	void HideTutorial()
	{
		bIsShowingTutorial = false;
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		ActivationParams.AddObject(n"Doll", GetAttributeObject(n"Doll"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Doll = Cast<AMatrioshkaActor>(ActivationParams.GetObject(n"Doll"));
		Player.MovementComponent.StartIgnoringActor(Doll);
		Player.AttachToComponent(Doll.Skelmesh, n"SmallBottom", EAttachmentRule::SnapToTarget);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		System::SetTimer(this, n"ShowTutorial", 1.5f, false);
		Player.OtherPlayer.DisableOutlineByInstigator(this);
		Player.CleanupCurrentMovementTrail();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(n"IsLeavingDoll"))
		{
			if (bIsShowingTutorial)
			{
				HideTutorial();
			}

			return;
		}

		if (IsActioning(n"IsEnteringDoll"))
		{	
			return;
		}
			
		if(IsActioning(n"Slapped") && HasControl())
		{
			Doll.PlayOnSlappedAnim();
		}

		if(IsActioning(ActionNames::MovementDash))
		{
			Doll.Shake();
			TimeShaking = 0;
		}

		TimeShaking += DeltaTime;

		if (HasControl() && ActiveDuration > 10)
		{
			Doll.AutoReleasePlayer();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetAttributeObject(n"Doll") == nullptr)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		HideTutorial();
		Player.MovementComponent.StopIgnoringActor(Doll);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.OtherPlayer.EnableOutlineByInstigator(this);
	}
}
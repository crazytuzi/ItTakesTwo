import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Foghorn.FoghornStatics;

class UClassicFlyingTutorialNewCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(n"ClassicFlyingTutorial");
	default CapabilityTags.Add(n"GameplayAction");
	default CapabilityDebugCategory = n"LevelSpecific";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;

	//OnGround
	UPROPERTY()
	FTutorialPrompt JumpStartHover;
	default JumpStartHover.Action = ActionNames::MovementJump;
	default JumpStartHover.MaximumDuration = -1;
	UPROPERTY()
	FTutorialPrompt DashStartHover;
	default DashStartHover.Action = ActionNames::MusicFlyingStart;
	default DashStartHover.MaximumDuration = -1;
	UPROPERTY()
	FTutorialPromptChain PromptChain;

	//Flying
	UPROPERTY()
	FTutorialPrompt Boost;
	default Boost.Action = ActionNames::MusicFlyingStart;
	default Boost.MaximumDuration = -1;
	UPROPERTY()
	FTutorialPrompt Up;
	default Up.Action = ActionNames::MusicHoverUp;
	default Up.MaximumDuration = -1;
	UPROPERTY()
	FTutorialPrompt Down;
	default Down.Action = ActionNames::MusicHoverDown;
	default Down.MaximumDuration = -1;


	bool bAllowShowStartOfTutorial = true;
	bool bAllowShowCurrentlyFlyingTutorial = false;
	bool bRemovedStartHoverTutorial = false;
	bool bRemovedCurrentlyFlyingTutorial = false;

	bool bStopShowingCurrentyFlyingTutorial;

	float TimeSpentFlying = 0;
	float TimeSpentNotFlying = 100;
	bool bPlayedFlyingVO = false;
	
	AHazeActor StartHoverInstigator;
	AHazeActor BoostInstigator;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);

		JumpStartHover.Text = FlyingComp.JumpText;
		DashStartHover.Text = FlyingComp.FlyText;
		Boost.Text = FlyingComp.BoostText;
		Up.Text = FlyingComp.UpText;
		Down.Text = FlyingComp.DownText;
		PromptChain.Prompts.Add(JumpStartHover);
		PromptChain.Prompts.Add(DashStartHover);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(FlyingComp.IsFlyingDisabled())
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"ClassicFlyingTutorial"))
     		return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"ClassicFlyingTutorial"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(FlyingComp.IsFlyingDisabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, Player);
		bAllowShowStartOfTutorial = true;
		bAllowShowCurrentlyFlyingTutorial = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		//PrintToScreen("FlyingComp.CurrentState " + FlyingComp.bIsFlying);
		//PrintToScreen("TimeSpentFlying " + TimeSpentFlying);
		//PrintToScreen("TimeSpentNotFlying " + TimeSpentNotFlying);
		//PrintToScreen("bAllowShowStartOfTutorial " + bAllowShowStartOfTutorial);
		
		if(FlyingComp.bIsFlying == true)
		{
			RemoveStartHoverTutorial();
			ShowCurrentlyFlyingTutorial();




			if(Player == Game::GetCody())
			{
				if(TimeSpentFlying >= 2.0)
				{
					if(bPlayedFlyingVO)
						return;

					bPlayedFlyingVO = true;

					if(Save::IsPersistentProfileFlagSet(EHazeSaveDataType::Progress, n"bPlayedFlyingVO") == true)
						return;
					
					Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, n"bPlayedFlyingVO", true);
					

					UFoghornVOBankDataAssetBase VOBank = FlyingComp.VODataBankAsset;
					FName EventName = n"FoghornSBMusicClassicHeavenReveal";
					PlayFoghornVOBankEvent(VOBank, EventName);
					//PrintToScreen("AAAAAAAAAAAAAAAAAAAAAAAAAA", 4.f);
				}
			}






			if(TimeSpentFlying >= 5)
				TimeSpentNotFlying = 0;
			else
				TimeSpentNotFlying = 20;
				
			TimeSpentFlying += DeltaTime;
			if(TimeSpentFlying >= 20.f)
			{
				bStopShowingCurrentyFlyingTutorial = true;
				RemoveCurrentyFlyingTutorialBoost();
			}
			else
			{
				bStopShowingCurrentyFlyingTutorial = false;
			}
		}
		else
		{
			RemoveCurrentyFlyingTutorialBoost();

			TimeSpentNotFlying += DeltaTime;
			if(TimeSpentNotFlying <= 20)
			{
				return;
			}
		
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			if(MoveComp.IsGrounded())
			{
				ShowStartHoverTutorial(0);
			}
			else
			{
				ShowStartHoverTutorial(1);
			}
		}
	}

	//Begin Hover Tutorial
	UFUNCTION()
	void ShowStartHoverTutorial(int ChainNumber)
	{
		if(bAllowShowStartOfTutorial)
		{
			ShowTutorialPromptChain(Player, PromptChain, this, 0);
			bAllowShowStartOfTutorial = false;
			bRemovedStartHoverTutorial = false;
		}

		if(ChainNumber == 0)
			SetTutorialPromptChainPosition(Player, this, 0);
		if(ChainNumber == 1)
			SetTutorialPromptChainPosition(Player, this, 1);
	}
	UFUNCTION()
	void RemoveStartHoverTutorial()
	{
		if(bRemovedStartHoverTutorial)
			return;

		bAllowShowStartOfTutorial = true;
		bRemovedStartHoverTutorial = true;
		RemoveTutorialPromptByInstigator(Player, this);
	}

	//Boost
	UFUNCTION()
	void ShowCurrentlyFlyingTutorial()
	{
		if(bStopShowingCurrentyFlyingTutorial)
			return;
		if(bAllowShowCurrentlyFlyingTutorial)
			return;

		bAllowShowCurrentlyFlyingTutorial = true;
		bRemovedCurrentlyFlyingTutorial = false;
		ShowTutorialPrompt(Player, Boost, Player);
		ShowTutorialPrompt(Player, Up, Player);
		ShowTutorialPrompt(Player, Down, Player);
	}
	UFUNCTION()
	void RemoveCurrentyFlyingTutorialBoost()
	{
		if(bRemovedCurrentlyFlyingTutorial)
			return;

		bAllowShowCurrentlyFlyingTutorial = false;
		bRemovedCurrentlyFlyingTutorial = true;
		RemoveTutorialPromptByInstigator(Player, Player);
	}
}
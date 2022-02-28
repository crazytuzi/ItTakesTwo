import Cake.LevelSpecific.Hopscotch.Baseball.BaseballManager;
import Cake.LevelSpecific.Hopscotch.Baseball.BaseballPlayerComponent;


class ABaseballPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Baseball");
	default CapabilityDebugCategory = n"Baseball";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	UBaseballPlayerComponent BaseballPlayerComponent;
	ABaseballManager BaseballManager;
	AHazePlayerCharacter MyPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ABaseballManager BaseballManagerLocal = Cast<ABaseballManager>(GetAttributeObject(n"BaseballManager"));
		if(BaseballManagerLocal == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(BaseballManagerLocal.bMiniGameActive == false)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BaseballManager.bMiniGameActive == false)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BaseballPlayerComponent = UBaseballPlayerComponent::GetOrCreate(MyPlayer);
		BaseballManager = Cast<ABaseballManager>(GetAttributeObject(n"BaseballManager"));
		BaseballManager.MiniGameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountDownFinished");
		//MyPlayer.AddCapabilitySheet(BaseballManager.MiniGameComp.PlayerBlockMovementCapabilitySheet);
		MyPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.TriggerMovementTransition(this);
		MyPlayer.BlockMovementSyncronization();


		if(MyPlayer == Game::GetMay())
		{
			MyPlayer.AddLocomotionFeature(BaseballManager.MayFeature);
		}
		else if(MyPlayer == Game::GetCody())
		{
			MyPlayer.AddLocomotionFeature(BaseballManager.CodyFeature);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(MyPlayer == Game::GetMay())
		{
		 	MyPlayer.RemoveLocomotionFeature(BaseballManager.MayFeature);
		}
		else if(MyPlayer == Game::GetCody())
		{
			MyPlayer.RemoveLocomotionFeature(BaseballManager.CodyFeature);
		}

	//	MyPlayer.RemoveCapabilitySheet(BaseballManager.MiniGameComp.PlayerBlockMovementCapabilitySheet);
		//MyPlayer.SetCapabilityAttributeObject(n"TrackRunner", nullptr);

		MyPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.DeactivateCameraByInstigator(this);
		MyPlayer.UnblockMovementSyncronization();

		BaseballPlayerComponent.DestroyComponent(MyPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"BaseBallToy";
		MyPlayer.RequestLocomotion(Locomotion);

		if(BaseballManager.bMiniGamePlaying == false)
			return;
			
		if(WasActionStarted(ActionNames::MovementDash))
		{
			if(MyPlayer == Game::GetMay())
			{
				if(MyPlayer.HasControl())
				{
					BaseballManager.MaysToyFigurine.Swing();
					BaseballManager.MaysToyFigurine.bPlayerTryingToSwing = true;
				}	
			}
			if(MyPlayer == Game::GetCody())
			{
				if(MyPlayer.HasControl())
				{
					BaseballManager.CodysToyFigurine.Swing();
					BaseballManager.CodysToyFigurine.bPlayerTryingToSwing = true;
				}
			}
		}
		
		if(WasActionStopped(ActionNames::MovementDash))
		{
			if(MyPlayer == Game::GetMay())
			{
				if(MyPlayer.HasControl())
				{
					BaseballManager.MaysToyFigurine.RetractSwing();
					BaseballManager.MaysToyFigurine.bPlayerTryingToSwing = false;
				}	
			}
			if(MyPlayer == Game::GetCody())
			{
				if(MyPlayer.HasControl())
				{
					BaseballManager.CodysToyFigurine.RetractSwing();
					BaseballManager.CodysToyFigurine.bPlayerTryingToSwing = false;
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void CountDownFinished()
	{
	
	}
}
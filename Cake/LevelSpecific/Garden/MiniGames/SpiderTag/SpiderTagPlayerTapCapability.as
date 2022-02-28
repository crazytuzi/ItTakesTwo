import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;

class USpiderTagPlayerTapCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SpiderTagPlayerTapCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"TagMinigame";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USpiderTagPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USpiderTagPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HasControl())
		{
			float DistanceFromother = (PlayerComp.OtherPlayersComp.Owner.ActorLocation - Owner.ActorLocation).Size();
			FVector OthersDirection = (PlayerComp.OtherPlayersComp.Owner.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			float Dot = Owner.ActorForwardVector.DotProduct(OthersDirection);

			if (DistanceFromother < 400.f)
			{
				if (WasActionStarted(ActionNames::PrimaryLevelAbility))
					return EHazeNetworkActivation::ActivateFromControl;
			}
		}
			
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (PlayerComp.bWeAreIt)
		{
			PlayerComp.OtherPlayersComp.bWeAreIt = true;
			PlayerComp.bWeAreIt = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}
}
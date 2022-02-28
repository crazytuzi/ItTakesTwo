import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;

class USnowFolkLookCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowFolkLookCapability");
	default CapabilityDebugCategory = n"SnowFolkLookCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 180;
	
	const FName LookActionName = n"LookProximity";

	ASnowfolkSplineFollower Folk;
	USnowFolkProximityComponent ProximityComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Folk = Cast<ASnowfolkSplineFollower>(Owner);
		ProximityComp = USnowFolkProximityComponent::Get(Owner);

		ProximityComp.OnEnterProximity.AddUFunction(this, n"HandlePlayerEnterProximity");
		ProximityComp.OnLeaveProximity.AddUFunction(this, n"HandlePlayerLeaveProximity");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Folk.bIsRecovering)
			return EHazeNetworkActivation::DontActivate;

		if (Folk.bIsHit)
			return EHazeNetworkActivation::DontActivate;

		if (Folk.bIsDown)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(LookActionName))
			return EHazeNetworkActivation::DontActivate;
			
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Folk.bIsRecovering)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Folk.bIsHit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Folk.bIsDown)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!IsActioning(LookActionName))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Folk.bEnableLookAt = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float BestDistance = MAX_flt;
		AHazePlayerCharacter BestPlayer = nullptr;
		for (auto Player : ProximityComp.ProximityPlayers)
		{
			float Distance = ProximityComp.GetDistance(Player);
			FVector Direction = (Player.ActorLocation - Folk.ActorLocation).GetSafeNormal();
			if (Folk.ActorForwardVector.DotProduct(Direction) > 0.4f && Distance < BestDistance)
			{
				BestDistance = Distance;
				BestPlayer = Player;
			}
		}

		if (BestPlayer != nullptr)
			Folk.LookAtLocation = BestPlayer.ActorCenterLocation;

		Folk.bEnableLookAt = (BestPlayer != nullptr);
	}

	UFUNCTION()	
	void HandlePlayerEnterProximity(AHazePlayerCharacter Player, bool bFirstEnter)
	{
		if (!bFirstEnter)
			return;

		Folk.SetCapabilityActionState(LookActionName, EHazeActionState::Active);
	}

	UFUNCTION()	
	void HandlePlayerLeaveProximity(AHazePlayerCharacter Player, bool bLastLeave)
	{
		if (!bLastLeave)
			return;

		Folk.SetCapabilityActionState(LookActionName, EHazeActionState::Inactive);
	}
}
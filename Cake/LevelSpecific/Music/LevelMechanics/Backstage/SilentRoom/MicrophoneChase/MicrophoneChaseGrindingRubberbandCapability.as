import Vino.Movement.Grinding.UserGrindComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;

class UMicrophoneChaseGrindingRubberbandCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Speed);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	UUserGrindComponent GrindComp;
	UCharacterMicrophoneChaseComponent ChaseComp;
	UHazeCrumbComponent CrumbComp;
	AHazePlayerCharacter Player;

	float DesiredSpeedDefault = 0.0f;

	float SpeedMultiplierCurrent = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		GrindComp = UUserGrindComponent::Get(Owner);
		ChaseComp = UCharacterMicrophoneChaseComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Network::IsNetworked())
			return EHazeNetworkActivation::DontActivate;

		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if(!GrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DesiredSpeedDefault = GrindComp.DesiredSpeed;
		SpeedMultiplierCurrent = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!ChaseComp.bLastGrind)
			return;

		float SpeedMultiplierTarget = GetRubberbandMultiplier();
		Player.SetCapabilityAttributeValue(n"GrindingSpeedOverride", DesiredSpeedDefault * (1.0f + SpeedMultiplierTarget));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!GrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	float GetRubberbandMultiplier() const
	{
		if(!IsOtherPlayerGrinding())
			return 0.0f;

		if (IsPlayerFirst(Player))
			return 0.f;
		
		if (Player.IsPlayerDead() || Player.GetOtherPlayer().IsPlayerDead())
			return 0.f;

		const float SizeMax = 3000.0f;
		float DistanceBetweenPlayers = FMath::Min((Player.ActorLocation - GetOtherPlayerLocation(Player)).Size(), SizeMax);
		const float Alpha = DistanceBetweenPlayers / SizeMax;
		const float DistanceAlpha = FMath::EaseIn(0.0f, 1.0f, Alpha, 2.0f);

		return DistanceAlpha;
	}

	bool IsPlayerFirst(AHazePlayerCharacter InPlayer) const
	{
		FVector OtherPlayerLocation = GetOtherPlayerLocation(InPlayer);

		FHazeSplineSystemPosition PlayerSplineLoc = GrindComp.ActiveGrindSpline.Spline.GetPositionClosestToWorldLocation(InPlayer.ActorLocation, true);
		FHazeSplineSystemPosition OtherPlayerSplineLoc = GrindComp.ActiveGrindSpline.Spline.GetPositionClosestToWorldLocation(OtherPlayerLocation, true);

		const float PlayerDist = GrindComp.ActiveGrindSpline.Spline.GetDistanceAlongSplineAtWorldLocation(PlayerSplineLoc.WorldLocation);
		const float OtherPlayerDist = GrindComp.ActiveGrindSpline.Spline.GetDistanceAlongSplineAtWorldLocation(OtherPlayerSplineLoc.WorldLocation);

		const bool bIsPlayerFirst = PlayerDist > OtherPlayerDist;
		return bIsPlayerFirst;
	}

	FVector GetOtherPlayerLocation(AHazePlayerCharacter InPlayer) const
	{
		const bool bIsNetworked = Network::IsNetworked();
		AHazePlayerCharacter OtherPlayer = InPlayer.OtherPlayer;
		const FVector OtherPlayerLocation = bIsNetworked ? GetPredictionLocation(OtherPlayer) : OtherPlayer.ActorLocation;
		return OtherPlayerLocation;
	}

	FVector GetPredictionLocation(AHazePlayerCharacter InPlayer) const
	{
		FHazeActorReplicationFinalized CrumbParams;
		UHazeCrumbComponent::Get(InPlayer).GetCurrentReplicatedData(CrumbParams);
		return CrumbParams.Location + CrumbParams.Velocity * Network::GetPingRoundtripSeconds() * 0.5f;
	}

	bool IsOtherPlayerGrinding() const
	{
		UUserGrindComponent OtherPlayerGrindComp = UUserGrindComponent::Get(Player.OtherPlayer);
		if(OtherPlayerGrindComp == nullptr)
			return false;

		return OtherPlayerGrindComp.HasActiveGrindSpline();
	}
}

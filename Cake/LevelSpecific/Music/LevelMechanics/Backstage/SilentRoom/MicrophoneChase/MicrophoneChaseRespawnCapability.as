import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseManager;

/*
	// Updates the location of the other player on the respawn spline.
*/

class UMicrophoneChaseRespawnCapability : UHazeCapability
{
	UMicrophoneChaseManagerComponent ChaseMgr;
	AHazePlayerCharacter Player;
	AHazePlayerCharacter OtherPlayer;

	float LastDistanceAlongSpline;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ChaseMgr = UMicrophoneChaseManagerComponent::GetOrCreate(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		OtherPlayer = Player.OtherPlayer;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(RespawnSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RespawnSpline.SplineRegionContainer.ActorEnteredSpline(Player);
		LastDistanceAlongSpline = DistanceAlongSpline;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float DistanceAlongSpline_OtherPlayer = DistanceAlongSpline;

		const bool bTravelingForward = DistanceAlongSpline_OtherPlayer > LastDistanceAlongSpline;

		RespawnSpline.SplineRegionContainer.UpdateRegionActivity(Player, DistanceAlongSpline_OtherPlayer, LastDistanceAlongSpline, bTravelingForward);

		LastDistanceAlongSpline = DistanceAlongSpline_OtherPlayer;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(RespawnSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	// While the condition in ShouldDeactivate requires respawn spline to be nullptr, we expect this sheet to be removed manually.
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(RespawnSpline != nullptr)
		{
			RespawnSpline.SplineRegionContainer.ActorLeftSpline(Player, ERegionExitReason::ActorExitedSpline);
		}
	}

	AMicrophoneChaseRespawnSpline GetRespawnSpline() const property
	{
		if(ChaseMgr.MicrophoneChaseMgr == nullptr)
			return nullptr;

		return ChaseMgr.MicrophoneChaseMgr.CurrentRespawnSpline;
	}

	float GetDistanceAlongSpline() const property
	{
		return RespawnSpline.Spline.GetDistanceAlongSplineAtWorldLocation(OtherPlayer.ActorLocation);
	}

}

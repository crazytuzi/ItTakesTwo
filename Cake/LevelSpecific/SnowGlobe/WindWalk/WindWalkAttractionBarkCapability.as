import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

class UWindWalkAttractionBarkCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WindWalk");
	default CapabilityDebugCategory = n"WindWalk";
	default TickGroup = ECapabilityTickGroups::GamePlay;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	AHazePlayerCharacter OtherPlayer;

	UWindWalkComponent WindWalk;
	UMagneticPlayerAttractionComponent PlayerAttraction;
	UMagneticPlayerAttractionComponent PlayerAttraction_Other;

	const float VOEventInterval = 1.f;
	float Timer;

	bool bCanFireVOEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		OtherPlayer = Player.OtherPlayer;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (UWindWalkComponent::Get(Player) == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (UMagneticPlayerAttractionComponent::Get(Player) == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (UMagneticPlayerAttractionComponent::Get(OtherPlayer) == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WindWalk = UWindWalkComponent::Get(Player);
		PlayerAttraction = UMagneticPlayerAttractionComponent::Get(Player);
		PlayerAttraction_Other = UMagneticPlayerAttractionComponent::Get(OtherPlayer);

		Timer = 0.f;
		bCanFireVOEvent = false;

		WindWalk.OnDash.AddUFunction(this, n"HandleWindWalkDash");
		PlayerAttraction.OnMagneticPlayerPerchingStartedEvent.AddUFunction(this, n"HandlePlayerStartedPerching");
		PlayerAttraction.OnMagneticPlayerPerchingEndedEvent.AddUFunction(this, n"HandlePlayerStoppedPerching");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WindWalk.OnDash.UnbindObject(this);
		PlayerAttraction.OnMagneticPlayerPerchingStartedEvent.UnbindObject(this);
	}

	UFUNCTION()
	void HandlePlayerStartedPerching(AHazePlayerCharacter PerchingPlayer, FVector PerchLocation)
	{
		OnStartedPerching(PerchingPlayer);
	}

	UFUNCTION()
	void HandlePlayerStoppedPerching(AHazePlayerCharacter PerchingPlayer, FVector PerchLocation)
	{
		OnStoppedPerching(PerchingPlayer);
	}

	UFUNCTION()
	void HandleWindWalkDash()
	{
		OnWindWalkDash();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Timer += DeltaTime;
		if(bCanFireVOEvent = Timer >= VOEventInterval)
			Timer = 0.f;

		if (bCanFireVOEvent)
		{
			// NOTE: PiggyBacking means the _other_ player is on our back right now
			// "Hold on!"
				if (PlayerAttraction.bIsPiggybacking)
					if (WindWalk.bIsHoldingOntoMagnetPole)
						if (WindWalk.GetWindForce().SizeSquared() > FMath::Square(500.f))
							OnHoldOnForce(WindWalk.GetWindForceScale());

			// Being swept away (not holding onto a pole)
			// And we're _not_ being piggybacked
			if (!PlayerAttraction_Other.bIsPiggybacking)
				if (!WindWalk.bIsHoldingOntoMagnetPole)
					if (WindWalk.GetWindForce().SizeSquared() > FMath::Square(500.f))
						OnSweptAwayForce(WindWalk.GetWindForceScale());
		}

		if (WindWalk.ActiveNoWindVolumes.Num() > 0)
		{
			FVector VolumeWindForce = FVector::ZeroVector;
			for(auto WindVolume : WindWalk.ActiveVolumes)
				VolumeWindForce += WindVolume.WindDirection * WindVolume.WindForce * WindVolume.WindForceScale;

			if (bCanFireVOEvent)
				if (WindWalk.GetWindForce().IsNearlyZero(100.f) && !VolumeWindForce.IsNearlyZero(100.f))
					OnSafeFromWindForce(VolumeWindForce.Size());
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnStartedPerching(AHazePlayerCharacter PerchingPlayer) {}

	UFUNCTION(BlueprintEvent)
	void OnStoppedPerching(AHazePlayerCharacter PerchingPlayer) {}

	UFUNCTION(BlueprintEvent)
	void OnHoldOnForce(float Force) {}

	UFUNCTION(BlueprintEvent)
	void OnSweptAwayForce(float Force) {}

	UFUNCTION(BlueprintEvent)
	void OnSafeFromWindForce(float Force) {}

	UFUNCTION(BlueprintEvent)
	void OnWindWalkDash() {}
}
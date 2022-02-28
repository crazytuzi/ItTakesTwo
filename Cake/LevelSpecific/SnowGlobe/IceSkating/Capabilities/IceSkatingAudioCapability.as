import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Peanuts.Foghorn.FoghornStatics;

class UIceSkatingAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(n"IceSkatingAudio");

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	UAkAudioEvent StartMaySkatingBreathEvent;

	UPROPERTY()
	UAkAudioEvent StartMaySkatingCatchBreathEvent;

	UPROPERTY()
	UAkAudioEvent StopMaySkatingBreathEvent;

	UPROPERTY()
	UAkAudioEvent StartCodySkatingBreathEvent;

	UPROPERTY()
	UAkAudioEvent StartCodySkatingCatchBreathEvent;

	UPROPERTY()
	UAkAudioEvent StopCodySkatingBreathEvent;

	private float ActiveMovementDuration = 0.f;
	private float LastActiveMovementDuration = 0.f;
	private bool bPendingCatchBreath = false;

	UFoghornManagerComponent FoghornManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		FoghornManager = UFoghornManagerComponent::Get(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(SkateComp.bForceEnter)
			return EHazeNetworkActivation::ActivateLocal;

		FHitResult GroundHit = SkateComp.GetGroundHit();
		if (IsSurfaceIceSkateable(GroundHit))
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"MovementAudio", this);

		// Since we are playing special breathing while this capability is active, we block all other foghorn efforts		
		FoghornManager.EffortManager.BlockActor(Player);

		UAkAudioEvent BreathEvent = Player.IsMay() ? StartMaySkatingBreathEvent : StartCodySkatingBreathEvent;
		bPendingCatchBreath = false;

		Player.PlayerHazeAkComp.HazePostEvent(BreathEvent);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(IsSkatingFast())
		{
			ActiveMovementDuration += DeltaTime;
			if(ActiveMovementDuration > 10)
				bPendingCatchBreath = true;
		}
		else		
		{
			ActiveMovementDuration -= (DeltaTime * 4);		
			if(bPendingCatchBreath && ActiveMovementDuration <= 2.f)
			{
				UAkAudioEvent CatchBreathEvent = Player.IsMay() ? StartMaySkatingCatchBreathEvent : StartCodySkatingCatchBreathEvent;
				Player.PlayerHazeAkComp.HazePostEvent(CatchBreathEvent);
				bPendingCatchBreath = false;
			}
		}

		ActiveMovementDuration = FMath::Clamp(ActiveMovementDuration, 0.f, 20.f);
		if(ActiveMovementDuration != LastActiveMovementDuration)
		{
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_VO_Efforts_MovementDuration_Skating", ActiveMovementDuration);
			LastActiveMovementDuration = ActiveMovementDuration;
		}
	}

	bool IsSkatingFast()
	{
		if(!SkateComp.bIsIceSkating)
			return false;

		FVector PlayerInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		return MoveComp.Velocity.Size() >= 100.f && PlayerInput.Size() > 0.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SkateComp.bForceEnter)
			return EHazeNetworkDeactivation::DontDeactivate;

		FHitResult GroundHit = SkateComp.GetGroundHit();
		if (IsSurfaceIceSkateable(GroundHit))
			return EHazeNetworkDeactivation::DontDeactivate;

		if(ActiveMovementDuration > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
 		Player.UnblockCapabilities(n"MovementAudio", this);	

		// Since we are playing special breathing while this capability is active, we block all other foghorn efforts		
		FoghornManager.EffortManager.ClearBlockedActor(Player);

		UAkAudioEvent BreathEvent = Player.IsMay() ? StopMaySkatingBreathEvent : StopCodySkatingBreathEvent;
		Player.PlayerHazeAkComp.HazePostEvent(BreathEvent);	
	}	
}
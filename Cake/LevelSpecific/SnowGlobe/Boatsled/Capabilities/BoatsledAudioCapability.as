import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledEventComponent;
import Peanuts.Audio.AudioStatics;

namespace BoatsledVOStrings
{
	const FName May_StartInteraction = n"FoghornSBSnowglobeTownBobsledIntro";

	const FName May_Whale_Sight = n"FoghornDBGameplayBarkBobsledWhaleEnterMay";
	const FName Cody_Whale_Sight = n"FoghornDBGameplayBarkBobsledWhaleEnterCody";

	const FName Cody_Whale_Inside = n"FoghornDBGameplayBarkBobsledWhaleInside";
};

class UBoatsledAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledAudioCapability);

	default CapabilityDebugCategory = BoatsledTags::Boatsled;

	UBoatsledComponent BoatsledComponent;
	UBoatsledEventComponent BoatsledEventHandler;
	UHazeMovementComponent BoatsledMovementComponent;

	UHazeAkComponent HazeAkComp;
	AHazePlayerCharacter PlayerOwner;

	bool bWhaleSightLinePlayed = false;

	UPROPERTY(BlueprintReadOnly)
	float CurrentSpeed;

	UPROPERTY(BlueprintReadOnly)
	bool bIsSleddingOnIce;

	UPROPERTY(BlueprintReadOnly)
	bool bIsSleddingOnWhale;

	UPROPERTY(BlueprintReadOnly)
	bool bIsInAir;

	UPROPERTY(BlueprintReadOnly)
	bool bIsPlayerPushingBoatsled;

	UPROPERTY(BlueprintReadOnly)
	bool bIsScrapingWall;


	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BoostEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactEvent;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
		BoatsledEventHandler = BoatsledComponent.BoatsledEventHandler;
		HazeAkComp = UHazeAkComponent::Get(Owner);
		BoatsledMovementComponent = BoatsledComponent.Boatsled.MovementComponent;

		// Set audio panning based on player character
		HazeAudio::SetPlayerPanning(HazeAkComp, PlayerOwner);

		// Bind events
		// Start/stop
		BoatsledEventHandler.OnBothPlayersWaitingForStart.AddUFunction(this, n"OnPlayersWaitingForStart");
		BoatsledEventHandler.OnBoatsledInteractionStarted.AddUFunction(this, n"OnBoatsledStart");
		BoatsledEventHandler.OnPlayerHoppingAboard.AddUFunction(this, n"OnPlayerHoppingAboard");
		BoatsledEventHandler.OnPlayerStoppedSledding.AddUFunction(this, n"OnBoatsledStop");

		// Jump stuff
		BoatsledEventHandler.OnBoatsledStartingJump.AddUFunction(this, n"OnBoatsledJump");
		BoatsledEventHandler.OnBoatsledLanding.AddUFunction(this, n"OnBoatsledLand");

		// Misc
		BoatsledEventHandler.OnBoatsledBoost.AddUFunction(this, n"OnBoatsledBoost");
		BoatsledEventHandler.OnBoatsledWhaleSleddingStarted.AddUFunction(this, n"OnBoatsledWhaleSleddingStarted");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateAudioParams();

		//AAngVelo
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_BoatSled_Skid", FMath::Abs(BoatsledComponent.SleddingBlendSpaceValue), 0.f);
		
		//Speed
		float BoatSledSpeed = HazeAudio::NormalizeRTPC01(CurrentSpeed, 0.f, 3600.f);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_BoatSled_Speed", BoatSledSpeed, 0.f);

		//InAir
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_BoatSled_InAir", bIsInAir ? 1.f : 0.f, 0.f);
		
		// 0: sledding on whale; 1: sledding on ice
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_BoatSled_IsIceORWhale", bIsSleddingOnWhale ? 0.f : 1.f, 0.f);

		// Player is pushing boatsled
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_BoatSled_IsPushing", bIsPlayerPushingBoatsled ? 1.f : 0.f, 0.f);

		// Eman TODO: Collisions are fucked up right now, fix fix fix
		// BoatsledMovement and BoatsledWhaleMovement capabilities will set action state on tick when checking for collisions
		// HazeAkComp.SetRTPCValue("Rtpc_Vehicle_BoatSled_IsScrapingAginstWall", bIsScrapingWall ? 1.f : 0.f, 0.f);

		float RawImpactForce = 0.f;
		float ImpactForceNorm = 0.f;

		if(ConsumeAttribute(n"BoatSledImpactAudio", RawImpactForce))
		{
			//PrintScaled("ImpactForce: " + RawImpactForce, 1.f);

			ImpactForceNorm = HazeAudio::NormalizeRTPC01(RawImpactForce, 0.f, 0.45f);

			HazeAkComp.SetRTPCValue("Rtpc_Vehicle_BoatSled_ImpactForce", ImpactForceNorm);
			HazeAkComp.HazePostEvent(ImpactEvent);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BoatsledComponent == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BoatsledComponent.Boatsled == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Post stop event in case we missed stop delegate
		HazeAkComp.HazePostEvent(StopEvent);

		// Clear whale jump event stuff
		ConsumeAction(n"OtherPlayerPlayedWhaleSightLine");
		bWhaleSightLinePlayed = false;

		// Start/stop
		BoatsledEventHandler.OnBothPlayersWaitingForStart.Unbind(this, n"OnPlayersWaitingForStart");
		BoatsledEventHandler.OnBoatsledInteractionStarted.Unbind(this, n"OnBoatsledStart");
		BoatsledEventHandler.OnPlayerHoppingAboard.Unbind(this, n"OnPlayerHoppingAboard");
		BoatsledEventHandler.OnPlayerStoppedSledding.Unbind(this, n"OnBoatsledStop");

		// Jump stuff
		BoatsledEventHandler.OnBoatsledStartingJump.Unbind(this, n"OnBoatsledJump");
		BoatsledEventHandler.OnBoatsledLanding.Unbind(this, n"OnBoatsledLand");

		// Eman TODO: Add impact event!

		BoatsledEventHandler.OnBoatsledBoost.Unbind(this, n"OnBoatsledBoost");
		BoatsledEventHandler.OnBoatsledWhaleSleddingStarted.Unbind(this, n"OnBoatsledWhaleSleddingStarted");
	}

	void UpdateAudioParams()
	{
		CurrentSpeed = BoatsledMovementComponent.Velocity.Size();

		bIsPlayerPushingBoatsled = BoatsledComponent.IsPushingSled();
		bIsSleddingOnWhale = BoatsledComponent.IsWhaleSledding();
		bIsSleddingOnIce = (BoatsledComponent.IsSledding() && !bIsSleddingOnWhale) || !bIsPlayerPushingBoatsled;
		bIsInAir = BoatsledComponent.IsJumping() || BoatsledComponent.IsFallingThroughChimney();
		bIsScrapingWall = IsActioning(BoatsledTags::BoatsledIsCollidingWithBarrier);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayersWaitingForStart()
	{
		if(PlayerOwner.IsMay())
			PlayFoghornVOBankEvent(BoatsledComponent.Boatsled.VOBank, BoatsledVOStrings::May_StartInteraction);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledStart()
	{
		HazeAkComp.HazePostEvent(StartEvent);
		bIsPlayerPushingBoatsled = true;

		//PrintScaled("Boatsled start", 1.f, FLinearColor::Green, 2.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerHoppingAboard()
	{
		//PrintScaled("Player hopped aboard", 1.f, FLinearColor::Green, 2.f);

		bIsPlayerPushingBoatsled = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledStop(AHazePlayerCharacter PlayerCharacter)
	{
		//PrintScaled("Boatsled Stop", 1.f, FLinearColor::Green, 2.f);

		HazeAkComp.HazePostEvent(StopEvent);

		bIsInAir = false;
		bIsPlayerPushingBoatsled = false;
		bIsSleddingOnIce = false;
		bIsSleddingOnWhale = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledJump(FBoatsledJumpParams BoatsledJumpParams)
	{
		if(BoatsledJumpParams.NextBoatsledState == EBoatsledState::WhaleSledding && !bWhaleSightLinePlayed && !IsActioning(n"OtherPlayerPlayedWhaleSightLine"))
		{
			FName EventName = PlayerOwner.IsMay() ?
				BoatsledVOStrings::May_Whale_Sight :
				BoatsledVOStrings::Cody_Whale_Sight;

			PlayFoghornVOBankEvent(BoatsledComponent.Boatsled.VOBank, EventName);

			if(HasControl())
				NetWhaleSightLinePlayed();
		}

		//PrintScaled("Boatsled jump", 1.f, FLinearColor::Green, 2.f);
	}

	UFUNCTION(NetFunction)
	void NetWhaleSightLinePlayed()
	{
		bWhaleSightLinePlayed = true;
		PlayerOwner.OtherPlayer.SetCapabilityActionState(n"OtherPlayerPlayedWhaleSightLine", EHazeActionState::Active);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledLand(FVector LandingVelocity)
	{
		//PrintScaled("Boatsled land", 1.f, FLinearColor::Green, 2.f);
	}

	// TODO: Add impact delegate
	// UFUNCTION(NotBlueprintCallable)
	// void OnBoatsledImpact() { }
	

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledBoost()
	{
		//PrintScaled("Boost!", 1.f, FLinearColor::Green, 2.f);

		HazeAkComp.HazePostEvent(BoostEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledWhaleSleddingStarted()
	{
		if(PlayerOwner.IsCody())
			PlayFoghornVOBankEvent(BoatsledComponent.Boatsled.VOBank, BoatsledVOStrings::Cody_Whale_Inside);
	}
}
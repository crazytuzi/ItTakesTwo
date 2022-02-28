import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;
import Cake.Environment.GPUSimulations.PurpleGuckCleanableByWater;
import Vino.PlayerHealth.PlayerHealthStatics;

class UWaterHoseAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaterHose");
	
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UWaterHoseComponent WaterHoseComp;
	UHazeAkComponent WaterHoseNozzleHazeAkComp;
	UHazeAkComponent WaterHoseImpactHazeAkComp;	

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EquipWaterHoseEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent UnequipWaterHoseEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFireWaterEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFireWaterEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartWaterGroundImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopWaterGroundImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartWaterImpactSoilEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopWaterImpactSoilEvent;

	UPROPERTY(Category = "Parameters")
	float ImpactStopDelay = 0.5f;

	UPROPERTY(Category = "Parameters")
	float ImpactEventChangedFadeOutMs = 3000.f;

	float LastRotation;
	float LastRotationDelta;
	float LastRotationDeltaRtpcValue;	
	
	UAkAudioEvent CurrentPlayImpactEvent = nullptr;
	UAkAudioEvent CurrentStopImpactEvent = nullptr;

	FHazeAudioEventInstance WaterImpactEventInstance;
	FHazeAudioEventInstance WaterShootEventInstance;

	float ImpactDelayedStopTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
		MoveComp = UHazeMovementComponent::Get(Owner);
		WaterHoseComp = UWaterHoseComponent::Get(Owner);
		WaterHoseNozzleHazeAkComp = UHazeAkComponent::Get(WaterHoseComp.WaterHose, n"WaterHoseNozzleHazeAkComp");	
		WaterHoseImpactHazeAkComp = UHazeAkComponent::Get(WaterHoseComp.WaterHose, n"WaterHoseImpactHazeAkComp");		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if(Player.bIsParticipatingInCutscene)	
			return EHazeNetworkActivation::DontActivate;

		if(IsPlayerDead(Player))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsPlayerDead(Player))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(WaterHoseImpactHazeAkComp.EventInstanceIsPlaying(WaterImpactEventInstance))
			WaterHoseImpactHazeAkComp.HazeStopEvent(WaterImpactEventInstance.PlayingID);

		if(WaterHoseNozzleHazeAkComp.EventInstanceIsPlaying(WaterShootEventInstance))
			WaterHoseNozzleHazeAkComp.HazeStopEvent(WaterShootEventInstance.PlayingID);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ConsumeAction(n"AudioEquipWaterHose") == EActionStateStatus::Active)
			if(EquipWaterHoseEvent != nullptr)
				WaterHoseNozzleHazeAkComp.HazePostEvent(EquipWaterHoseEvent);

		if(ConsumeAction(n"AudioUnEquipWaterHose") == EActionStateStatus::Active)
			if(UnequipWaterHoseEvent != nullptr)
				WaterHoseNozzleHazeAkComp.HazePostEvent(UnequipWaterHoseEvent);

		if(ConsumeAction(n"AudioStartShootWater") == EActionStateStatus::Active)
			StartShootWaterAudio();
		
		if(ConsumeAction(n"AudioStopShootWater") == EActionStateStatus::Active)
			StopShootWaterAudio();	

		CalculateHoseMovementValue(DeltaSeconds);		

		FVector HitLocation;	
		UWaterHoseImpactComponent WaterImpactComp;
		UAkAudioEvent WantedImpactEvent;		

		if(ConsumeAction(n"AudioHandleWaterImpact") == EActionStateStatus::Active)
		{
			// New impact started, so reset delay timer
			ImpactDelayedStopTimer = 0.f;

			// True if we are shooting and got impacts
			if(HandleProjectileImpact(HitLocation, WaterImpactComp, WantedImpactEvent))
			{
				WaterHoseImpactHazeAkComp.SetWorldLocation(HitLocation);		

				if(!IsPlayingImpactEvent() || CurrentPlayImpactEvent != WantedImpactEvent)
				{
					// If the impact has changed and 
					// if we are currently playing another impact we stop the old one with a fadeout
					if(WaterImpactEventInstance.PlayingID != 0)
						WaterHoseImpactHazeAkComp.HazeStopEvent(WaterImpactEventInstance.PlayingID, ImpactEventChangedFadeOutMs);
				
					// Start playing new impact loop
					WaterImpactEventInstance = WaterHoseImpactHazeAkComp.HazePostEvent(WantedImpactEvent);
					CurrentPlayImpactEvent = WantedImpactEvent;
				}			

				SetImpactRtpcs(WaterImpactComp);
			}		
		}

		if(IsPlayingImpactEvent())
		{
			// We've started playing the impact loop, check if it's time to stop it
			if(ShouldStopImpactLoop(DeltaSeconds))
			{
				WaterHoseImpactHazeAkComp.HazePostEvent(CurrentStopImpactEvent);
			}
				
		}

		//Print("Current impact event: " + CurrentPlayImpactEvent, 0.f);
	}

	UFUNCTION()
	void StartShootWaterAudio()
	{
		if(StartFireWaterEvent != nullptr)
			WaterShootEventInstance = WaterHoseNozzleHazeAkComp.HazePostEvent(StartFireWaterEvent);
	}

	UFUNCTION()
	void StopShootWaterAudio()
	{
		if(StopFireWaterEvent != nullptr)
			WaterHoseNozzleHazeAkComp.HazePostEvent(StopFireWaterEvent);
	}

	void CalculateHoseMovementValue(float DeltaSeconds)
	{
		float CurrRotation = Owner.GetActorRotation().Yaw;
		float CurrRotationDelta = CurrRotation - LastRotation;

		//if(FMath::Abs(CurrRotationDelta) > 0.001f)
		//	CurrRotationDelta = FMath::Sign(CurrRotationDelta);
		//else
		//	CurrRotationDelta = 0.f;

		CurrRotationDelta = FMath::Abs(CurrRotationDelta);
		float RtpcValue = FMath::Clamp(HazeAudio::NormalizeRTPC01(CurrRotationDelta, 0.f, 1.2f), 0.f, 1.f);	
	
		if(LastRotationDeltaRtpcValue != RtpcValue)
		{
			//WaterHoseNozzleHazeAkComp.SetRTPCValue(HazeAudio::RTPC::WaterHoseMovementSpeed, RtpcValue);
			HazeAudio::SetGlobalRTPC(HazeAudio::RTPC::WaterHoseMovementSpeed, RtpcValue, 0.f);
			LastRotationDeltaRtpcValue = 0.f;
		}	

		LastRotationDelta = CurrRotationDelta;
		LastRotation = CurrRotation;		
	}

	UFUNCTION()
	bool HandleProjectileImpact(FVector& OutImpactLocation, UWaterHoseImpactComponent& OutWaterImpactComp,
		UAkAudioEvent& OutAudioEvent)
	{
		const FHitResult HitResult = WaterHoseComp.LastWaterHit;		

		if(!HitResult.bBlockingHit)
			return false;

		bool bImpactOverride = false;

		OutImpactLocation = HitResult.Location;
		// Check if we are impacting an actor with a WaterHoseImpact-component
		if(HitResult.Actor != nullptr)
		{
			OutWaterImpactComp = UWaterHoseImpactComponent::Get(HitResult.Actor);
			if(OutWaterImpactComp != nullptr)
			{
				if(OutWaterImpactComp.ValidateImpact(HitResult.Component) && !OutWaterImpactComp.bFullyWatered)
				{
					// Found WaterHoseImpactComponent, update current set of play/stop events
					OutAudioEvent = OutWaterImpactComp.OnWaterStartImpactEvent;
					CurrentStopImpactEvent = OutWaterImpactComp.OnWaterStopImpactEvent;
					bImpactOverride = true;
				}
			}		

			// If we're watering soil, update current set of play/stop events
			if(Cast<ASubmersibleSoil>(HitResult.Actor) != nullptr)
			{
				OutAudioEvent = StartWaterImpactSoilEvent;
				CurrentStopImpactEvent = StopWaterImpactSoilEvent;
				bImpactOverride = true;
			}				
		}

		if(!bImpactOverride || OutAudioEvent == nullptr && CurrentStopImpactEvent == nullptr)
		{
			OutAudioEvent = StartWaterGroundImpactEvent;
			CurrentStopImpactEvent = StopWaterGroundImpactEvent;		
		}		

		return true;
	}

	bool IsPlayingImpactEvent()
	{
		return WaterHoseImpactHazeAkComp.HazeIsEventActive(WaterImpactEventInstance.EventID);
	}
	
	bool ShouldStopImpactLoop(float DeltaSeconds)
	{
		ImpactDelayedStopTimer += DeltaSeconds;
		if(!(ImpactDelayedStopTimer >= ImpactStopDelay))
			return false;

		ImpactDelayedStopTimer = 0.f;
		return true;
	}

	void SetImpactRtpcs(UWaterHoseImpactComponent ImpactComp)
	{
		if(!IsPlayingImpactEvent())
			return;

		float SoilWateredRtpcValue = 0.f;
		if(ConsumeAttribute(n"AudioSoilWateredAmount", SoilWateredRtpcValue))
			SetSoilRtpc(SoilWateredRtpcValue);	
			
		auto ImpactActor = WaterHoseComp.LastWaterHit.Actor;
		if(Cast<ACleanableSurface>(ImpactActor) != nullptr)
			SetPurpleGuckRtpc(ImpactComp);
		else if(ImpactComp != nullptr)
			SetWaterableFlowerRtpc(ImpactComp);		
	}

	void SetSoilRtpc(float RtpcValue)
	{
		WaterHoseImpactHazeAkComp.SetRTPCValue(HazeAudio::RTPC::WaterHoseSoilWetAmount, RtpcValue);
	}

	void SetPurpleGuckRtpc(UWaterHoseImpactComponent ImpactComp)
	{
		
	}

	void SetWaterableFlowerRtpc(UWaterHoseImpactComponent ImpactComp)
	{
		WaterHoseImpactHazeAkComp.SetRTPCValue(HazeAudio::RTPC::WaterHoseFlowerFillAmount, ImpactComp.GetCurrentWaterLevel());
	}

}





